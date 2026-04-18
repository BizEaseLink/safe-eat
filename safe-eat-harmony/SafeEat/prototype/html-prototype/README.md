# Safe-Eat HTML Prototype

这套页面用于给华为 AI 读取并转换为 ArkTS 页面，不需要构建，直接打开 HTML 即可。建议先从 `prototype-flow.html` 看整体页面关系。

## 页面清单

- `home.html`
- `scan.html`
- `result.html`
- `menu-month.html`
- `menu-day.html`
- `profile.html`
- `membership.html`
- `feedback.html`
- `prototype-flow.html`

## 配套文件

- `styles.css`：统一视觉与组件规范落地
- `prototype-api.js`：示例请求层与本地历史结构说明

## 交接建议

1. 把本目录下全部文件提供给华为 AI。
2. 同时提供 `safe-eat-harmony/API对接说明.md`。
3. 告诉华为 AI：页面按本目录的结构与注释生成 ArkTS，接口按 `prototype-api.js` 的方法名与请求说明接。
4. 本地图片历史使用应用沙盒，不依赖服务端原图回显。
