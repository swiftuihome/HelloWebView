# 在 SwiftUI 中通过 WKWebView 与网页交互

在现代 iOS 开发中，我们有时需要在原生应用中嵌入网页内容，并与网页进行交互。例如，点击网页上的按钮弹出原生提示框，或者从原生控制网页行为。在 SwiftUI 中，虽然没有原生的 WebView 组件，但我们可以通过 WKWebView 结合 UIViewRepresentable 实现这一功能。

本文将带你逐步构建一个支持交互的 Web 视图，在 SwiftUI 中加载 Bootstrap 网页，并实现网页与原生代码之间的消息通信。



## 效果展示

你将构建一个包含两个按钮的网页：

- 点击“**Bootstrap 弹窗**”按钮，网页内部弹出一个样式美观的 Bootstrap 弹窗。
- 点击“**SwiftUI 弹窗**”按钮，将触发原生 SwiftUI 弹窗，展示跨层交互能力。



## 一、基础结构设计

我们首先定义一个 SwiftUI 容器视图 BootstrapWebView，其中嵌入自定义的 WebView，并监听网页发出的消息：

```swift
struct BootstrapWebView: View {
    @State private var showAlert = false
    
    var body: some View {
        WebView(showAlert: $showAlert)
            .edgesIgnoringSafeArea(.all)
            .alert("提示", isPresented: $showAlert) {
                Button("确定") { print("点击了确定") }
                Button("取消", role: .cancel) { print("点击了取消") }
            } message: {
                Text("这是从网页触发的 SwiftUI 弹窗")
            }
    }
}
```

这个视图的关键在于 @State 管理弹窗状态，通过绑定将弹窗的显示控制权交给子视图中的 WebView。



## 二、包装 WKWebView

由于 SwiftUI 没有直接支持 WebView，我们需要使用 UIViewRepresentable 将 UIKit 的 WKWebView 封装成 SwiftUI 组件。

```swift
struct WebView: UIViewRepresentable {
    @Binding var showAlert: Bool
    
    func makeCoordinator() -> WebViewCoordinator {
        let coordinator = WebViewCoordinator()
        coordinator.onMessage = { msg in
            if msg == "open" {
                showAlert = true
            }
        }
        return coordinator
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let contentController = WKUserContentController()
        contentController.add(context.coordinator, name: "showAlert")
        
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
```

通过 WKUserContentController 和 WKScriptMessageHandler，我们可以让网页与原生代码进行通信。只要网页通过 window.webkit.messageHandlers.showAlert.postMessage("open") 发送消息，SwiftUI 就会收到并响应。



## 三、消息处理协调器 Coordinator

在 SwiftUI 与 UIKit 的桥接中，Coordinator 是重要的桥梁，我们通过它来实现消息监听：

```swift
class WebViewCoordinator: NSObject, WKScriptMessageHandler {
    var onMessage: ((String) -> Void)?
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "showAlert", let msg = message.body as? String {
            onMessage?(msg)
        }
    }
}
```

这个类实现了 WKScriptMessageHandler 协议，监听网页发来的 showAlert 消息，并通过闭包通知 SwiftUI。



## 四、HTML 内容嵌入与交互按钮

我们可以将网页 HTML 内容直接作为字符串嵌入代码中（也可以从本地文件或 URL 加载）：

```html
<!DOCTYPE html>
<html lang="zh-CN">

<head>
    <meta charset="UTF-8">
    <title>弹窗示例</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- 引入 Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        .hero-section {
            max-width: 600px;
            margin: 0 auto;
        }
    </style>
</head>

<body class="p-4 d-flex flex-column justify-content-center min-vh-100 bg-light">
    <div class="hero-section text-center p-4 bg-white rounded-3 shadow-sm">
        <h1 class="text-primary mb-3 fw-bold">Hello Bootstrap</h1>
        <p class="lead text-muted mb-4">这是一个在 SwiftUI 中集成的响应式网页，使用 Bootstrap 5 构建。</p>

        <!-- 响应式按钮组 -->
        <div class="d-flex flex-column flex-md-row justify-content-center gap-2">
            <button type="button" class="btn btn-primary px-4" data-bs-toggle="modal" data-bs-target="#exampleModal">
                <i class="bi bi-window"></i> Bootstrap弹窗
            </button>

            <button type="button" class="btn btn-success px-4"
                onclick="window.webkit.messageHandlers.showAlert.postMessage('open')">
                <i class="bi bi-apple"></i> SwiftUI弹窗
            </button>
        </div>
    </div>

    <!-- Modal 弹窗结构 -->
    <div class="modal fade" id="exampleModal" tabindex="-1" aria-labelledby="exampleModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="exampleModalLabel">提示</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="关闭"></button>
                </div>
                <div class="modal-body">
                    <p>这是一个 Bootstrap 弹窗，来自 WKWebView 页面。</p>
                    <p class="text-muted small mt-2">点击下方按钮或外部区域关闭</p>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">关闭</button>
                </div>
            </div>
        </div>
    </div>

    <!-- 引入 Bootstrap Icons 和 JS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
</body>

</html>
```

注意按钮 onclick 调用的 JS 代码，这是与 SwiftUI 通信的核心：

```swift
window.webkit.messageHandlers.showAlert.postMessage('open')
```



## 五、关键点总结

| **功能**             | **实现方式**             |
| -------------------- | ------------------------ |
| 加载网页             | WKWebView.loadHTMLString |
| SwiftUI 嵌套原生视图 | UIViewRepresentable      |
| 网页与原生通信       | WKScriptMessageHandler   |
| SwiftUI 弹窗         | .alert 绑定状态          |
| 跨平台 UI 样式       | 使用 Bootstrap           |



## 六、实际应用场景

这种网页与原生交互的方式适用于：

- 嵌入第三方网页内容但希望保留部分原生交互；
- 原生 APP 与后台 Web 系统集成；
- 快速构建可定制的展示页（例如营销页面）；
- 支持渐进式功能替换，将部分 Web 功能迁移为原生实现。



## 结语

通过本文你已经学会如何在 SwiftUI 中集成 WKWebView 并实现与网页的交互。你可以在实际项目中灵活扩展，比如从网页传递更多消息、向网页注入脚本，甚至结合 WKNavigationDelegate 控制加载行为。
