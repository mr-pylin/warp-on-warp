# 🗽 Warp On Warp
Warp-On-Warp configurations based on a wide range of Cloudflare clean IPs and zeroteam.top API for secure internet access.

**Notes**
   - IPv4 and IPv6 range IPs come from [cloudflare.com/ips](https://www.cloudflare.com/ips/).
   - Zeroteam API: [api.zeroteam.top/warp?format=sing-box](https://api.zeroteam.top/warp?format=sing-box).


## 🛠️ Usage
   - **Android 🤖 / Linux 🐧 / Mac ⌘ :**
      
      Copy and Paste below commands:
      ```bash
      curl -sSL https://raw.githubusercontent.com/mr-pylin/warp-on-warp/main/warp.sh -o warp.sh && chmod +x warp.sh && bash warp.sh
      ```

   - **Windows ⊞ :**
      1. Execute `scanner.bat` (modified version of [warp-yg](https://github.com/yonggekkk/warp-yg) v23.11.15)
      2. You have to have `warp.exe`, `..\subnets_v4.txt` and `..\subnets_v6.txt` locally available with the same layout as this repository.
      3. Wait for the execution to create `result.csv`.
      4. Copy and Paste below commands where `result.csv` is located:
      ```bash
      curl -sSL https://raw.githubusercontent.com/mr-pylin/warp-on-warp/main/warp.sh -o warp.sh && chmod +x warp.sh && bash warp.sh
      ```

## 📝 TODO
   - [ ] Adding support for IPv6.

## 🔗 Usefull Links
   - **Termux**: Terminal Simulator app. [[GitHub Link](https://github.com/termux/termux-app)]
   - **Hiddify**: Internet Freedom Solution. [[Direct Link](https://app.hiddify.com/)]

## ©️ Credits
- [Elfina Tech](https://github.com/Elfiinaa) : The idea about Warp-on-Warp.
- [Yonggekkk](https://github.com/yonggekkk/warp-yg) : Warp IP scanner for windows.
- [Azavax](https://github.com/azavaxhuman/Quick_Warp_on_Warp) : Base concepts