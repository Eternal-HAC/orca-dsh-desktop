using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Threading.Tasks;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace OrcaWebView2Harness
{
    internal static class Program
    {
        internal static int ExitCode;

        [STAThread]
        private static int Main(string[] args)
        {
            try
            {
                Options options = Options.Parse(args);
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                Application.Run(new HarnessForm(options));
                return ExitCode;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex);
                return 2;
            }
        }
    }

    // Developer-only WebView2 host. It neither starts DSH nor reads OrcaDSH
    // production data; the orchestration script owns its temporary DSH host.
    internal sealed class HarnessForm : Form
    {
        private readonly Options options;
        private readonly JavaScriptSerializer json = new JavaScriptSerializer();
        private readonly string webViewData;
        private WebView2 webView;

        public HarnessForm(Options options)
        {
            this.options = options;
            webViewData = Path.Combine(options.Output, "webview2-user-data");
            Text = "OrcaDSH WebView2 visual harness";
            StartPosition = FormStartPosition.Manual;
            Location = new Point(-2000, -2000);
            ClientSize = new Size(options.Width, options.Height);
            Shown += async (sender, args) => await RunAsync();
        }

        private async Task RunAsync()
        {
            try
            {
                Directory.CreateDirectory(options.Output);
                CoreWebView2Environment environment = await CoreWebView2Environment.CreateAsync(null, webViewData, null);
                webView = new WebView2 { Dock = DockStyle.Fill };
                Controls.Add(webView);
                await webView.EnsureCoreWebView2Async(environment);
                string selectionFixture = String.IsNullOrEmpty(options.SessionId)
                    ? ""
                    : "localStorage.setItem('dsh.sessions.current', JSON.stringify({sessionId:" + json.Serialize(options.SessionId) + "}));";
                await webView.CoreWebView2.AddScriptToExecuteOnDocumentCreatedAsync("window.__orcaHarnessErrors=[];" + selectionFixture + "window.addEventListener('error',e=>window.__orcaHarnessErrors.push(String(e.message||e.error||'error')));window.addEventListener('unhandledrejection',e=>window.__orcaHarnessErrors.push(String(e.reason||'unhandled rejection')));");
                webView.CoreWebView2.Settings.AreDevToolsEnabled = false;
                webView.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
                webView.CoreWebView2.NavigationCompleted += async (sender, args) => await ProbeWhenReadyAsync(args);
                webView.Source = new Uri(options.Url);
            }
            catch (Exception ex)
            {
                WriteFailure("initialization", ex);
                Close();
            }
        }

        private async Task ProbeWhenReadyAsync(CoreWebView2NavigationCompletedEventArgs navigation)
        {
            if (!navigation.IsSuccess)
            {
                WriteFailure("navigation", new InvalidOperationException("Navigation failed: " + navigation.WebErrorStatus));
                Close();
                return;
            }

            File.WriteAllText(Path.Combine(options.Output, "notice-dismiss.json"), await DismissStartupNoticeAsync());
            DateTime deadline = DateTime.UtcNow.AddSeconds(options.TimeoutSeconds);
            string probe = null;
            while (DateTime.UtcNow < deadline)
            {
                probe = await ExecuteProbeAsync();
                if (ProbeHasMountedCompanion(probe)) break;
                await Task.Delay(500);
            }

            if (!ProbeHasMountedCompanion(probe))
            {
                File.WriteAllText(Path.Combine(options.Output, "probe-timeout.json"), probe ?? "{\"error\":\"probe did not execute\"}");
                WriteFailure("mount", new TimeoutException("Orca status companion did not mount before timeout."));
                Close();
                return;
            }

            File.WriteAllText(Path.Combine(options.Output, "probe-wide.json"), probe);
            AssertProbeLayout("wide", probe, "full");
            await ResizeAndProbeAsync(700);
            await ApplyCompactFixtureAsync(487);
            string compactProbe = await ExecuteProbeAsync();
            File.WriteAllText(Path.Combine(options.Output, "probe-compact.json"), compactProbe);
            AssertProbeLayout("compact", compactProbe, "compact");
            AssertCompactUsable(compactProbe);
            await ClearCompactFixtureAsync();
            string narrowProbe = await ResizeAndProbeAsync(320);
            File.WriteAllText(Path.Combine(options.Output, "probe-narrow.json"), narrowProbe);
            AssertProbeLayout("narrow", narrowProbe, "hidden");
            await ResizeAndWriteAsync("wide-restored", options.Width);
            await CaptureScreenshotAsync();
            File.WriteAllText(Path.Combine(options.Output, "result.json"), "{\"status\":\"PASS\",\"url\":" + json.Serialize(options.Url) + "}");
            Close();
        }

        private async Task ResizeAndWriteAsync(string name, int width)
        {
            string probe = await ResizeAndProbeAsync(width);
            File.WriteAllText(Path.Combine(options.Output, "probe-" + name + ".json"), probe);
        }

        private async Task<string> ResizeAndProbeAsync(int width)
        {
            ClientSize = new Size(width, options.Height);
            await Task.Delay(350);
            return await ExecuteProbeAsync();
        }

        private async Task ApplyCompactFixtureAsync(int width)
        {
            string script = @"(() => {
  const companion = document.querySelector('.orca-status-companion');
  let element = companion?.parentElement;
  let anchor = null;
  let sawLayoutContainer = false;
  while (element) {
    const style = getComputedStyle(element);
    const measuredWidth = element.getBoundingClientRect().width;
    if (style.display === 'contents' && sawLayoutContainer) break;
    if (style.display !== 'contents' && measuredWidth > 0) {
      sawLayoutContainer = true;
      if (anchor === null || measuredWidth >= anchor.getBoundingClientRect().width) anchor = element;
    }
    element = element.parentElement;
  }
  if (!anchor) return false;
  anchor.dataset.orcaHarnessResponsiveTarget = 'true';
  anchor.style.setProperty('width', '" + width + @"px', 'important');
  anchor.style.setProperty('min-width', '" + width + @"px', 'important');
  anchor.style.setProperty('max-width', '" + width + @"px', 'important');
  anchor.style.setProperty('flex', '0 0 " + width + @"px', 'important');
  return true;
})()";
            await webView.CoreWebView2.ExecuteScriptAsync(script);
            await Task.Delay(500);
        }

        private async Task ClearCompactFixtureAsync()
        {
            const string script = @"(() => {
  const anchor = document.querySelector('[data-orca-harness-responsive-target=""true""]');
  if (!anchor) return false;
  anchor.style.removeProperty('width');
  anchor.style.removeProperty('min-width');
  anchor.style.removeProperty('max-width');
  anchor.style.removeProperty('flex');
  delete anchor.dataset.orcaHarnessResponsiveTarget;
  return true;
})()";
            await webView.CoreWebView2.ExecuteScriptAsync(script);
            await Task.Delay(350);
        }

        private void AssertProbeLayout(string name, string probe, string expected)
        {
            var value = json.Deserialize<Dictionary<string, object>>(probe);
            var companion = value["companion"] as Dictionary<string, object>;
            string actual = companion == null || !companion.ContainsKey("layout") ? null : Convert.ToString(companion["layout"]);
            if (!String.Equals(actual, expected, StringComparison.Ordinal))
                throw new InvalidOperationException(name + " companion layout was " + (actual ?? "<missing>") + ", expected " + expected + ".");
        }

        private void AssertCompactUsable(string probe)
        {
            var value = json.Deserialize<Dictionary<string, object>>(probe);
            var responsive = value["responsiveContainer"] as Dictionary<string, object>;
            double responsiveWidth = responsive == null ? 0 : Convert.ToDouble(responsive["width"]);
            if (responsiveWidth < 360 || responsiveWidth >= 520)
                throw new InvalidOperationException("Compact responsive container width was " + responsiveWidth + ", expected 360-519px.");
            foreach (string key in new[] { "companion", "tokenMonitor", "composer", "textarea", "sendButton", "liangControl" })
            {
                var rect = value[key] as Dictionary<string, object>;
                if (rect == null || Convert.ToDouble(rect["width"]) <= 0 || Convert.ToDouble(rect["height"]) <= 0 || Convert.ToString(rect["display"]) == "none")
                    throw new InvalidOperationException("Compact layout element was not visibly laid out: " + key);
            }
            var overlaps = value["overlaps"] as Dictionary<string, object>;
            if (overlaps == null) throw new InvalidOperationException("Compact overlap evidence missing.");
            foreach (var pair in overlaps)
                if (Convert.ToBoolean(pair.Value)) throw new InvalidOperationException("Compact layout overlap detected: " + pair.Key);
        }

        private async Task<string> DismissStartupNoticeAsync()
        {
            const string script = @"(() => {
  const button = [...document.querySelectorAll('button')].find((element) => /继续|continue/i.test([element.getAttribute('aria-label'), element.title, element.innerText, element.textContent].filter(Boolean).join(' ')));
  if (!button) return JSON.stringify({ dismissed: false, reason: 'startup notice control not found' });
  button.click();
  return JSON.stringify({ dismissed: true, text: (button.innerText || button.getAttribute('aria-label') || '').trim() });
})()";
            string quoted = await webView.CoreWebView2.ExecuteScriptAsync(script);
            await Task.Delay(250);
            return json.Deserialize<string>(quoted);
        }

        private async Task<string> ExecuteProbeAsync()
        {
            const string script = @"(() => {
  const rect = (element) => {
    if (!element) return null;
    const r = element.getBoundingClientRect(); const s = getComputedStyle(element);
    return { exists: true, display: s.display, visibility: s.visibility, pointerEvents: s.pointerEvents,
      width: Math.round(r.width * 10) / 10, height: Math.round(r.height * 10) / 10,
      left: Math.round(r.left * 10) / 10, top: Math.round(r.top * 10) / 10,
      right: Math.round(r.right * 10) / 10, bottom: Math.round(r.bottom * 10) / 10,
      text: (element.innerText || element.textContent || '').trim(), layout: element.dataset.layout || null };
  };
  const companion = document.querySelector('.orca-status-companion');
  const token = document.querySelector('.orca-token-monitor');
  const composer = document.querySelector('textarea')?.closest('form') || document.querySelector('textarea')?.parentElement;
  const textarea = document.querySelector('textarea');
  const send = [...document.querySelectorAll('button')].find(x => /send|发送/i.test(x.getAttribute('aria-label') || x.title || x.innerText || '')) || null;
  // This selector is supplied by the bundled Liang plugin itself. It targets
  // the effort control, not the full-page decorative backdrop.
  const liang = document.querySelector('.liang-effort-control');
  const overlaps = (a, b) => {
    if (!a || !b) return null;
    const ar = a.getBoundingClientRect(); const br = b.getBoundingClientRect();
    if (ar.width <= 0 || ar.height <= 0 || br.width <= 0 || br.height <= 0) return false;
    return ar.left < br.right && ar.right > br.left && ar.top < br.bottom && ar.bottom > br.top;
  };
  const companionAncestors = [];
  let responsiveContainer = null;
  let sawLayoutContainer = false;
  for (let node = companion?.parentElement, depth = 0; node && depth < 6; node = node.parentElement, depth += 1) {
    const r = node.getBoundingClientRect(); const s = getComputedStyle(node);
    companionAncestors.push({ tag: node.tagName, className: typeof node.className === 'string' ? node.className.slice(0, 180) : '',
      width: Math.round(r.width * 10) / 10, height: Math.round(r.height * 10) / 10, display: s.display,
      flexDirection: s.flexDirection, justifyContent: s.justifyContent, alignItems: s.alignItems });
    if (s.display === 'contents' && sawLayoutContainer) break;
    if (s.display !== 'contents' && r.width > 0) {
      sawLayoutContainer = true;
      if (responsiveContainer === null || r.width >= responsiveContainer.getBoundingClientRect().width) responsiveContainer = node;
    }
  }
  const interactive = [...document.querySelectorAll('button, [role=""button""], a, [data-session-id], [data-sessionid]')].slice(0, 80).map((element) => ({
    tag: element.tagName, role: element.getAttribute('role'), sessionId: element.getAttribute('data-session-id') || element.getAttribute('data-sessionid'),
    text: (element.innerText || element.getAttribute('aria-label') || element.title || '').trim().slice(0, 180),
    className: typeof element.className === 'string' ? element.className.slice(0, 180) : ''
  }));
  return JSON.stringify({ viewport: { width: window.innerWidth, height: window.innerHeight },
    companion: rect(companion), responsiveContainer: rect(responsiveContainer), companionAncestors, tokenMonitor: rect(token), composer: rect(composer), textarea: rect(textarea), sendButton: rect(send), liangControl: rect(liang),
    overlaps: { companionToken: overlaps(companion, token), companionTextarea: overlaps(companion, textarea), companionSend: overlaps(companion, send), companionLiang: overlaps(companion, liang), tokenTextarea: overlaps(token, textarea), tokenSend: overlaps(token, send), tokenLiang: overlaps(token, liang), liangTextarea: overlaps(liang, textarea), liangSend: overlaps(liang, send) },
    interactive,
    pluginResources: performance.getEntriesByType('resource').map(x => x.name).filter(x => x.includes('/plugins/')),
    moduleLoaderKeys: Object.keys(window.__ModuleLoader__ || {}),
    errors: window.__orcaHarnessErrors || [] });
})()";
            string quoted = await webView.CoreWebView2.ExecuteScriptAsync(script);
            return json.Deserialize<string>(quoted);
        }

        private bool ProbeHasMountedCompanion(string probe)
        {
            if (String.IsNullOrEmpty(probe)) return false;
            try
            {
                var value = json.Deserialize<Dictionary<string, object>>(probe);
                var companion = value["companion"] as Dictionary<string, object>;
                return companion != null && companion.ContainsKey("exists") && Convert.ToBoolean(companion["exists"]);
            }
            catch { return false; }
        }

        private async Task CaptureScreenshotAsync()
        {
            try
            {
                using (FileStream stream = File.Create(Path.Combine(options.Output, "webview.png")))
                    await webView.CoreWebView2.CapturePreviewAsync(CoreWebView2CapturePreviewImageFormat.Png, stream);
            }
            catch (Exception ex) { File.WriteAllText(Path.Combine(options.Output, "screenshot-error.txt"), ex.ToString()); }
        }

        private void WriteFailure(string stage, Exception ex)
        {
            Program.ExitCode = 1;
            Directory.CreateDirectory(options.Output);
            File.WriteAllText(Path.Combine(options.Output, "failure.json"), json.Serialize(new { stage = stage, error = ex.ToString() }));
        }

        protected override void Dispose(bool disposing)
        {
            if (disposing && webView != null) webView.Dispose();
            base.Dispose(disposing);
        }
    }

    internal sealed class Options
    {
        public string Url;
        public string Output;
        public int TimeoutSeconds = 30;
        public int Width = 1400;
        public int Height = 700;
        public string SessionId;

        public static Options Parse(string[] args)
        {
            var result = new Options();
            for (int index = 0; index < args.Length; index += 2)
            {
                if (index + 1 >= args.Length) throw new ArgumentException("Missing value for " + args[index]);
                string name = args[index].ToLowerInvariant(); string value = args[index + 1];
                if (name == "--url") result.Url = value;
                else if (name == "--output") result.Output = value;
                else if (name == "--timeout") result.TimeoutSeconds = Int32.Parse(value);
                else if (name == "--width") result.Width = Int32.Parse(value);
                else if (name == "--height") result.Height = Int32.Parse(value);
                else if (name == "--session-id") result.SessionId = value;
                else throw new ArgumentException("Unknown option " + args[index]);
            }
            if (String.IsNullOrWhiteSpace(result.Url) || String.IsNullOrWhiteSpace(result.Output))
                throw new ArgumentException("Usage: --url <http://127.0.0.1:port> --output <directory> [--timeout seconds] [--width px] [--height px]");
            return result;
        }
    }
}
