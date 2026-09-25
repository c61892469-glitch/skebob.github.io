<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>skebob.vip - Index</title>
    <link rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%238acc14' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Crect x='3' y='11' width='18' height='11' rx='2' ry='2'%3E%3C/rect%3E%3Cpath d='M7 11V7a5 5 0 0 1 10 0v4'%3E%3C/path%3E%3C/svg%3E">
    <style>
        :root {
            --bg-deep: #0e0e0e;
            --bg-box: #1e1e1e;
            --bg-header: #282828;
            --bg-nav: #252525;
            --border-dark: #101010;
            --border-light: #303030;
            --text-main: #cccccc;
            --text-muted: #888888;
            --accent-green: #8acc14;
        }

        * { box-sizing: border-box; margin: 0; padding: 0; font-family: Tahoma, Verdana, Arial, sans-serif; font-size: 11px; }
        body { background-color: var(--bg-deep); color: var(--text-main); min-height: 100vh; display: flex; flex-direction: column; }
        .top-line { height: 2px; width: 100%; background: linear-gradient(90deg, #101010 0%, var(--accent-green) 50%, #101010 100%); position: fixed; top: 0; left: 0; z-index: 1000; }
        .forum-wrapper { width: 95%; max-width: 920px; margin: 25px auto 40px auto; }
        
        .f-box { background: var(--bg-box); border: 1px solid var(--border-dark); margin-bottom: 10px; border-radius: 2px; }
        .f-header { background: var(--bg-header); padding: 6px 10px; font-weight: bold; color: #dddddd; border-bottom: 1px solid var(--border-dark); }
        .f-content { padding: 12px; border-top: 1px solid var(--border-light); line-height: 1.5; color: #bbbbbb; }
        
        .f-nav { background: var(--bg-nav); border: 1px solid var(--border-dark); padding: 5px 10px; display: flex; justify-content: space-between; align-items: center; margin-top: 8px; margin-bottom: 8px; }
        .f-nav-links { display: flex; gap: 10px; }
        .f-nav a { color: var(--text-main); text-decoration: none; font-size: 10px; }
        .f-nav a:hover, .f-nav a.active { color: #ffffff; text-decoration: underline; font-weight: bold; }

        .status-table { width: 100%; border-collapse: collapse; }
        .status-table td { padding: 6px 10px; border-bottom: 1px solid var(--border-dark); }
        .status-table tr:last-child td { border-bottom: none; }
        .status-label { color: var(--text-muted); width: 40%; }
        .status-value { color: #ffffff; font-weight: bold; }
        .status-green { color: var(--accent-green); font-weight: bold; }
    </style>
</head>
<body>
    <div class="top-line"></div>
    <div class="forum-wrapper">
        <div class="f-box">
            <div class="f-content" style="padding: 8px 12px;">
                <div style="font-size: 20px; font-weight: bold; cursor: pointer;" onclick="location.href='index.html'">
                    <span style="color: #fff;">skebob</span><span style="color: #8acc14;">.vip</span>
                </div>
                <div class="f-nav">
                    <div class="f-nav-links">
                        <a href="index.html" class="active">Index</a>
                        <a href="forum.html">Configs & Luas</a>
                        <a href="profile.html">User Control Panel</a>
                    </div>
                    <div><a href="rules.html" style="color: var(--accent-green);">Rules</a></div>
                </div>
            </div>
        </div>

        <div class="f-box">
            <div class="f-header">System Information & Announcements</div>
            <div class="f-content">
                Welcome back to <b>skebob.vip</b>. Software build is fully updated and operational for Counter-Strike 2.
            </div>
        </div>

        <div class="f-box">
            <div class="f-header">Account Overview</div>
            <div class="f-content" style="padding: 0;">
                <table class="status-table">
                    <tr>
                        <td class="status-label">User Role</td>
                        <td class="status-green">Creator</td>
                    </tr>
                    <tr>
                        <td class="status-label">Subscription Status</td>
                        <td class="status-green">Active (Lifetime)</td>
                    </tr>
                    <tr>
                        <td class="status-label">Total Shared Configs</td>
                        <td class="status-value" id="user-cfgs-count">Loading...</td>
                    </tr>
                    <tr>
                        <td class="status-label">Software Build</td>
                        <td class="status-value">v2.4.1 [RELEASE]</td>
                    </tr>
                </table>
            </div>
        </div>
    </div>

    <script>
        async function loadStats() {
            try {
                const res = await fetch('api.php?action=list_configs');
                const data = await res.json();
                document.getElementById('user-cfgs-count').innerText = data.length;
            } catch(e) {
                document.getElementById('user-cfgs-count').innerText = '0';
            }
        }
        loadStats();
    </script>
</body>
</html>
