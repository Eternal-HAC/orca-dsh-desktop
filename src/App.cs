using System;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Net.Sockets;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;

namespace DeepSeekHarness
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    internal sealed class MainForm : Form
    {
        private const int Port = 3080;
        private readonly string baseDir;
        private readonly string nodePath;
        private readonly string dshPath;
        private readonly StringBuilder errorTail = new StringBuilder();
        private WebView2 webView;
        private Process serverProc;
        private bool shuttingDown;

        public MainForm()
        {
            baseDir = AppDomain.CurrentDomain.BaseDirectory;
            nodePath = Path.Combine(baseDir, "node.exe");
            dshPath = Path.Combine(baseDir, "node_modules", "@deepseek-ai", "dsh", "lib", "bin.js");

            Text = "DeepSeek Harness";
            ClientSize = new Size(1280, 820);
            StartPosition = FormStartPosition.CenterScreen;
            BackColor = Color.White;
            try { Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath); } catch { }
            Shown += async delegate { await InitializeAsync(); };
        }

        private async Task InitializeAsync()
        {
            try
            {
                StartServerIfNeeded();

                await InitializeWebViewAsync();
            }
            catch (Exception ex)
            {
                string detail = ex.ToString() + "\r\n\r\n" + ErrorTailText();
                try { File.WriteAllText(Path.Combine(baseDir, "dsh-app-error.log"), detail); } catch { }
                MessageBox.Show("DeepSeek Harness 启动失败：\r\n\r\n" + ex.Message + ErrorTailText(),
                    "DeepSeek Harness", MessageBoxButtons.OK, MessageBoxIcon.Error);
                BeginInvoke(new Action(Close));
            }
        }

        // WebView2 初始化（带重试：偶发 E_ABORT，多为上一次实例未完全退出导致，稍候重试即可）
        private async Task InitializeWebViewAsync()
        {
            Exception last = null;
            for (int attempt = 1; attempt <= 3; attempt++)
            {
                Exception ex = await TryCreateWebViewAsync();
                if (ex == null) return;
                last = ex;
                if (attempt < 3)
                {
                    await Task.Delay(2000 * attempt);
                    Application.DoEvents();
                }
            }
            throw last;
        }

        // 成功返回 null；失败返回异常并清理控件
        private async Task<Exception> TryCreateWebViewAsync()
        {
            WebView2 view = null;
            try
            {
                view = new WebView2 { Dock = DockStyle.Fill };
                Controls.Add(view);

                string userData = Path.Combine(
                    Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                    "DeepSeekHarness", "EBWebView");
                CoreWebView2Environment env = await CoreWebView2Environment.CreateAsync(null, userData, null);
                await view.EnsureCoreWebView2Async(env);

                view.CoreWebView2.Settings.AreDevToolsEnabled = false;
                view.CoreWebView2.Settings.AreDefaultContextMenusEnabled = false;
                view.CoreWebView2.Settings.IsStatusBarEnabled = false;
                view.Source = new Uri("http://127.0.0.1:" + Port);
                webView = view;
                return null;
            }
            catch (Exception ex)
            {
                try { if (view != null) { Controls.Remove(view); view.Dispose(); } } catch { }
                webView = null;
                return ex;
            }
        }

        private void StartServerIfNeeded()
        {
            if (IsPortOpen(Port))
            {
                AdoptExistingServer();
                return;
            }

            if (!File.Exists(nodePath)) throw new FileNotFoundException("未找到运行时：node.exe 不存在于程序目录。", nodePath);
            if (!File.Exists(dshPath)) throw new FileNotFoundException("未找到 dsh 入口：node_modules/@deepseek-ai/dsh 不存在。", dshPath);

            ProcessStartInfo psi = new ProcessStartInfo();
            psi.FileName = nodePath;
            psi.Arguments = "\"" + dshPath + "\" web";
            psi.WorkingDirectory = baseDir;
            psi.UseShellExecute = false;
            psi.CreateNoWindow = true;
            psi.RedirectStandardOutput = true;
            psi.RedirectStandardError = true;

            serverProc = Process.Start(psi);
            if (serverProc == null) throw new Exception("无法启动 dsh 服务进程。");

            serverProc.OutputDataReceived += delegate { };
            serverProc.ErrorDataReceived += delegate (object s, DataReceivedEventArgs e)
            {
                if (e.Data != null)
                {
                    lock (errorTail)
                    {
                        if (errorTail.Length > 8000) errorTail.Remove(0, 4000);
                        errorTail.AppendLine(e.Data);
                    }
                }
            };
            serverProc.BeginOutputReadLine();
            serverProc.BeginErrorReadLine();

            DateTime deadline = DateTime.UtcNow.AddSeconds(90);
            while (DateTime.UtcNow < deadline)
            {
                if (serverProc.HasExited)
                    throw new Exception("dsh 服务进程已退出。" + ErrorTailText());
                if (IsPortOpen(Port)) return;
                Thread.Sleep(1000);
            }
            throw new Exception("等待 dsh 服务就绪超时（90 秒）。" + ErrorTailText());
        }

        // 若端口已被本目录安装的 dsh 服务占用（例如上次异常残留），接管该进程，
        // 使关闭窗口时也能一并停止，避免遗留后台服务。
        private void AdoptExistingServer()
        {
            try
            {
                string marker = Path.Combine(baseDir, "node_modules", "@deepseek-ai", "dsh", "lib", "bin.js")
                    .Replace('/', '\\').ToLowerInvariant();
                using (System.Management.ManagementObjectSearcher searcher =
                    new System.Management.ManagementObjectSearcher(
                        "SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name = 'node.exe'"))
                {
                    foreach (System.Management.ManagementObject o in searcher.Get())
                    {
                        string cmd = Convert.ToString(o["CommandLine"]);
                        if (cmd == null) continue;
                        if (cmd.ToLowerInvariant().IndexOf(marker, StringComparison.Ordinal) >= 0)
                        {
                            int pid = Convert.ToInt32(o["ProcessId"]);
                            try { serverProc = Process.GetProcessById(pid); break; } catch { }
                        }
                    }
                }
            }
            catch { }
        }

        private static bool IsPortOpen(int port)
        {
            try
            {
                using (TcpClient client = new TcpClient())
                {
                    IAsyncResult ar = client.BeginConnect("127.0.0.1", port, null, null);
                    if (!ar.AsyncWaitHandle.WaitOne(1500)) return false;
                    client.EndConnect(ar);
                    return true;
                }
            }
            catch { return false; }
        }

        private string ErrorTailText()
        {
            lock (errorTail)
            {
                string t = errorTail.ToString().Trim();
                return t.Length == 0 ? "" : "\r\n\r\n服务日志（尾部）：\r\n" + t;
            }
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (!shuttingDown && serverProc != null)
            {
                shuttingDown = true;
                try
                {
                    if (!serverProc.HasExited) serverProc.Kill();
                    serverProc.WaitForExit(3000);
                }
                catch { }
                try { serverProc.Dispose(); } catch { }
                serverProc = null;
            }
            base.OnFormClosing(e);
        }
    }
}





