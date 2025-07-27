//
//  BootstrapWebView.swift
//  HelloWebView
//
//  Created by devlink on 2025/7/27.
//

import SwiftUI
import WebKit

// SwiftUI 视图容器，用于展示 WebView 并处理弹窗状态
struct BootstrapWebView: View {
    
    // 使用 @State 管理弹窗显示状态
    @State private var showAlert = false
    
    var body: some View {
        WebView(showAlert: $showAlert)
            .edgesIgnoringSafeArea(.all)
            .alert("提示", isPresented: $showAlert) {
                Button("确定", role: .none) {
                    print("点击了确定")
                }
                Button("取消", role: .cancel) {
                    print("点击了取消")
                }
            } message: {
                Text("这是从网页触发的 SwiftUI 弹窗")
            }
    }
}

// UIViewRepresentable 协议实现，将 WKWebView 包装为 SwiftUI 视图
struct WebView: UIViewRepresentable {
    
    // 绑定到 SwiftUI 的弹窗状态
    @Binding var showAlert: Bool
    
    
    // 创建并配置 Coordinator
    func makeCoordinator() -> WebViewCoordinator {
        let coordinator = WebViewCoordinator()
        coordinator.onMessage = { msg in
            // 当接收到消息内容为 "open" 时，设置 showAlert 为 true
            if msg == "open" {
                showAlert = true
            }
        }
        return coordinator
    }
    
    // 创建 WKWebView 实例
    func makeUIView(context: Context) -> WKWebView {
        // 创建用户内容控制器，用于处理网页与原生代码的通信
        let contentController = WKUserContentController()
        // 添加消息处理器，监听名为 "showAlert" 的消息
        // 当网页发送此消息时，会调用 Coordinator 的 userContentController 方法
        contentController.add(context.coordinator, name: "showAlert")
        
        // 创建 WKWebView 配置
        let config = WKWebViewConfiguration()
        // 将用户内容控制器设置到配置中
        config.userContentController = contentController
        
        
        // 使用配置创建 WKWebView 实例
        let webView = WKWebView(frame: .zero, configuration: config)
        
        // 加载 HTML 字符串
        let htmlContent = """
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
                /* 移动端按钮间距 */
                .btn-group-vertical > .btn {
                    margin-bottom: 10px;
                }
                /* 桌面端按钮间距 */
                @media (min-width: 768px) {
                    .btn-group-horizontal > .btn {
                        margin-right: 12px;
                    }
                }
            </style>
        </head>
        
        <body class="p-4 d-flex flex-column justify-content-center min-vh-100 bg-light">
            <div class="hero-section text-center p-4 bg-white rounded-3 shadow-sm">
                <!-- 图标 -->
                <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" fill="#0d6efd" class="bi bi-window-stack mb-3" viewBox="0 0 16 16">
                    <path d="M4.5 6a.5.5 0 1 0 0-1 .5.5 0 0 0 0 1M6 6a.5.5 0 1 0 0-1 .5.5 0 0 0 0 1m2-.5a.5.5 0 1 1-1 0 .5.5 0 0 1 1 0"/>
                    <path d="M12 1a2 2 0 0 1 2 2 2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2 2 2 0 0 1-2-2V3a2 2 0 0 1 2-2zM2 12V5a2 2 0 0 1 2-2h9a1 1 0 0 0-1-1H2a1 1 0 0 0-1 1v8a1 1 0 0 0 1 1m1-4v5a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1V8z"/>
                </svg>
                
                <h1 class="text-primary mb-3 fw-bold">Hello Bootstrap</h1>
                <p class="lead text-muted mb-4">这是一个在 SwiftUI 中集成的响应式网页，使用 Bootstrap 5 构建。</p>
                
                <!-- 响应式按钮组 -->
                <div class="d-flex flex-column flex-md-row justify-content-center gap-2">
                    <button type="button" class="btn btn-primary px-4" data-bs-toggle="modal" data-bs-target="#exampleModal">
                        <i class="bi bi-window"></i> Bootstrap弹窗
                    </button>
                    
                    <button type="button" class="btn btn-success px-4" onclick="window.webkit.messageHandlers.showAlert.postMessage('open')">
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
        """
        
        // 加载 HTML 字符串到 WebView
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }
    
    // 当 SwiftUI 的状态更新时调用此方法
    // 在这个简单示例中，我们不需要实现任何更新逻辑
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

// Coordinator 类，用于处理网页与原生代码之间的通信
class WebViewCoordinator: NSObject, WKScriptMessageHandler {
    // 定义消息处理回调闭包
    var onMessage: ((String) -> Void)?
    
    // 实现 WKScriptMessageHandler 协议方法
    // 当网页通过 messageHandlers 发送消息时调用此方法
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // 检查消息名称是否为 "showAlert"
        if message.name == "showAlert", let msg = message.body as? String {
            // 调用回调闭包，传递消息内容
            onMessage?(msg)
        }
    }
}
