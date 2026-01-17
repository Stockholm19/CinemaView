//
//  ContentView.swift
//  CinemaView
//
//  Created by Роман Пшеничников on 10.05.2025.
//

#if os(iOS)
import UIKit
typealias PlatformViewRepresentable = UIViewRepresentable
#elseif os(macOS)
import AppKit
typealias PlatformViewRepresentable = NSViewRepresentable
#endif

import SwiftUI
import WebKit

struct WebView: PlatformViewRepresentable {
    let url: URL
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var progress: Double
    @Binding var webViewReference: WKWebView?

    #if os(iOS)
    func makeUIView(context: Context) -> WKWebView {
        makeWebView(context: context)
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    #elseif os(macOS)
    func makeNSView(context: Context) -> WKWebView {
        makeWebView(context: context)
    }
    func updateNSView(_ nsView: WKWebView, context: Context) {}
    #endif

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    private func makeWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        
        #if os(iOS)
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        #endif

        let blocker = WKUserScript(source: Self.networkBlockerScript,
                                   injectionTime: .atDocumentStart,
                                   forMainFrameOnly: false)
        config.userContentController.addUserScript(blocker)

        let css = WKUserScript(source: Self.cssOverrideScript,
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: false)
        config.userContentController.addUserScript(css)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.navigationDelegate = context.coordinator
        
        // Add observer for progress
        context.coordinator.observation = webView.observe(\.estimatedProgress, options: [.new]) { wv, _ in
            DispatchQueue.main.async {
                self.progress = wv.estimatedProgress
            }
        }
        
        webView.load(URLRequest(url: url))
        
        DispatchQueue.main.async {
            self.webViewReference = webView
        }
        
        return webView
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        var observation: NSKeyValueObservation?

        init(parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            updateStates(webView)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            updateStates(webView)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            updateStates(webView)
        }

        private func updateStates(_ webView: WKWebView) {
            DispatchQueue.main.async {
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.parent.isLoading = webView.isLoading
            }
        }
    }

    private static let networkBlockerScript = #"""
    (function() {
        const blocked=/clarity\.ms|franeski\.net|adsbygoogle|doubleclick\.net/;
        const F=window.fetch;
        window.fetch=function(r,i){
            const u=typeof r==="string"?r:r.url;
            return blocked.test(u)?Promise.resolve(new Response('',{status:204})):F.apply(this,arguments);
        };
        const O=XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open=function(m,u){
            if(blocked.test(u)){this.abort();return;}
            return O.apply(this,arguments);
        };
    })();
    """#

    private static let cssOverrideScript = #"""
    (function(){
        const css=`
            #top,.b-top-banner,.b-side-banner,.b-footer,.b-bottom-banner{display:none!important;}
            .b-dwnapp{display:none!important;}
            html,body,#wrapper,#main{margin:0!important;padding:0!important;width:100%!important;}
            body[style*="padding-top"],body.has-brand.active-brand.pp.fixed-header.no-touch{padding-top:0!important;margin-top:0!important;}
            body.has-brand.active-brand.pp.fixed-header.no-touch::before{content:none!important;display:none!important;}`;
        const style=document.createElement('style');
        style.textContent=css;
        document.documentElement.prepend(style);
        document.documentElement.style.visibility='hidden';

        const show=()=>{document.documentElement.style.visibility='visible'};
        if(document.readyState==='complete'||document.readyState==='interactive'){show();}
        else document.addEventListener('DOMContentLoaded',show,{once:true});
        setTimeout(show,5000);

        const tidy=()=>{
            document.body.style.paddingTop='0';
            document.body.style.marginTop='0';
            document.body.classList.remove('has-brand');
            const s=document.body.firstElementChild;
            if(s&&s.tagName==='DIV'&&s.offsetHeight>50&&!s.children.length){s.remove();}
            document.querySelectorAll('.b-dwnapp').forEach(e=>e.remove());
        };
        tidy();
        new MutationObserver(tidy).observe(document.body,{childList:true,attributes:true});
    })();
    """#
}

struct ContentView: View {
    let initialURL = URL(string: "https://rezka.ag/")!
    
    @StateObject private var favoritesStore = FavoritesStore()
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var isLoading = false
    @State private var progress: Double = 0
    @State private var webView: WKWebView? = nil
    @State private var showFavorites = false

    var body: some View {
        #if os(macOS)
        content
            .frame(minWidth: 800, minHeight: 600)
        #else
        content
        #endif
    }
    
    var content: some View {
        VStack(spacing: 0) {
            if isLoading && progress < 1.0 {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 2)
            } else {
                Divider().frame(height: 2).background(Color.clear)
            }
            
            WebView(url: initialURL,
                    canGoBack: $canGoBack,
                    canGoForward: $canGoForward,
                    isLoading: $isLoading,
                    progress: $progress,
                    webViewReference: $webView)
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { webView?.goBack() }) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!canGoBack)
                
                Button(action: { webView?.goForward() }) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!canGoForward)
                
                Button(action: { webView?.reload() }) {
                    Image(systemName: "arrow.clockwise")
                }
                
                Spacer()
                
                Button(action: {
                    if let url = webView?.url {
                        favoritesStore.toggle(title: webView?.title ?? "Кино", url: url)
                    }
                }) {
                    Image(systemName: favoritesStore.isFavorite(url: webView?.url) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                
                Button(action: { showFavorites.toggle() }) {
                    Image(systemName: "list.bullet")
                }
                
                Button(action: { 
                    webView?.load(URLRequest(url: initialURL))
                }) {
                    Image(systemName: "house")
                }
            }
        }
        .sheet(isPresented: $showFavorites) {
            FavoritesView(store: favoritesStore) { url in
                webView?.load(URLRequest(url: url))
                showFavorites = false
            }
            #if os(macOS)
            .frame(width: 300, height: 400)
            #endif
        }
    }
}

struct FavoritesView: View {
    @ObservedObject var store: FavoritesStore
    var onSelect: (URL) -> Void
    
    var body: some View {
        VStack {
            HStack {
                Text("Избранное")
                    .font(.headline)
                Spacer()
                #if os(iOS)
                EditButton()
                #endif
            }
            .padding()
            
            List {
                ForEach(store.items) { item in
                    Button(action: { onSelect(item.url) }) {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.body)
                                .lineLimit(1)
                            Text(item.url.absoluteString)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(1)
                        }
                    }
                }
                .onDelete(perform: store.remove)
            }
        }
    }
}

