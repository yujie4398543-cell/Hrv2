# HealthMirror iOS（个人本地版）

SwiftUI + HealthKit + CoreMotion 原生 iPhone App。当前是可由 GitHub Actions 生成**未签名 IPA**的工程，不是已签名安装包，也尚未经过 Xcode 真机编译验证。

## 目前功能
- 今日：心率、静息心率、HRV、血氧、呼吸频率、腕温、步数、活动能量、睡眠概览
- 趋势：周/月/年页面框架（历史趋势图后续完善）
- 呼吸：呼吸练习页面框架
- 设置：隐私与数据说明
- 数据来源：Apple Health / HealthKit；步数在健康数据没有结果时尝试 CoreMotion

没有真实样本时显示“暂无数据”，不会生成假数据。心率、血氧、睡眠、腕温等取决于 Apple Watch 型号、地区、系统、设备是否已写入 Apple 健康及用户授权。

## 用 GitHub Actions 构建 IPA（iPhone 可操作）
1. 在 GitHub 新建一个 **Private** 仓库，例如 `HealthMirror`。
2. 将本项目 ZIP 解压后，把里面所有文件和 `.github` 隐藏目录一起上传到仓库根目录。可用 GitHub 网页端的 Add file / Upload files；若网页端不便上传整个目录，可先在 iPhone 的“文件”App 解压，再用 GitHub 网页上传文件。`.github/workflows/build-unsigned-ipa.yml` 必须保留原路径。
3. 确认默认分支为 `main`。
4. 打开仓库 **Actions**，选择 **Build unsigned iOS IPA**，点 **Run workflow**。首次也可在上传到 main 后自动触发。
5. 构建成功后进入该次运行页面底部 **Artifacts**，下载 `HealthMirror-unsigned-ipa`，解压后得到 `HealthMirror-unsigned.ipa` 和 `HealthMirror.entitlements`。
6. 将 IPA 导入你使用的签名工具，选择与你的证书/描述文件匹配的签名方式。若工具支持自定义 Entitlements，请使用随包提供的 `HealthMirror.entitlements`，并确保最终签名 profile 允许 `com.apple.developer.healthkit`。
7. 在 iPhone 上安装后，打开“健康”App检查是否出现 HealthMirror 的数据访问授权项，再回到本 App 请求授权。

## 签名与 HealthKit 关键说明
- 此工作流故意生成**未签名 IPA**，不需要把证书私钥放进 GitHub。
- 未签名 IPA 不能直接安装；必须由签名工具用有效证书重新签名。
- HealthKit 需要最终安装包的签名 entitlement 与 provisioning profile 匹配。只把 `HealthMirror.entitlements` 文件放在 IPA 旁边，不代表权限已经生效；签名工具必须把 entitlement 正确写入签名，并且 profile 允许该能力。
- 如果签名工具只能普通重签、不能配置 HealthKit entitlement，App 可能能安装，但无法正常请求 HealthKit 权限。需先做小范围验证，不能保证所有企业证书/共享证书都支持。
- 请勿把 `.p12`、证书密码、Apple ID 密码发到聊天或提交到 Git 仓库。若以后切换为 GitHub 云端签名，应仅使用 GitHub Secrets，并先确认你有权使用该证书。

## 当前工程设置
- iOS Deployment Target：17.0
- Bundle ID：`app.healthmirror.personal`（后续如签名工具要求特定 Bundle ID，需同步修改 `project.yml`）
- HealthKit entitlement：`com.apple.developer.healthkit = true`
- Info 使用说明：HealthKit 读取说明、Motion 读取说明
- 数据策略：当前不接入第三方服务器；本版也尚未实现独立的历史数据库或 iCloud 备份。

## 已知限制 / 下一阶段
- 本项目 ZIP 尚未在 Xcode 真机环境编译测试；GitHub Actions 首次运行会作为实际编译检查。
- 趋势页当前为展示框架，不是完整历史统计图。
- 呼吸页计时逻辑和逐阶段动画还需完善。
- 饮水量、日照等未连接数据源的项目不能当作真实测量值。
- iCloud 备份暂不启用，避免先引入额外 entitlement 和签名变量。
