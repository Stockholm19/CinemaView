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

    func makeCoordinator() -> Coordinator { Coordinator() }

    private func makeWebView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()

        let blocker = WKUserScript(source: Self.networkBlockerScript,
                                   injectionTime: .atDocumentStart,
                                   forMainFrameOnly: false)
        config.userContentController.addUserScript(blocker)

        let css = WKUserScript(source: Self.cssOverrideScript,
                               injectionTime: .atDocumentStart,
                               forMainFrameOnly: false)
        config.userContentController.addUserScript(css)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "macOS Safari"
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: url))
        return webView
    }

    class Coordinator: NSObject, WKNavigationDelegate {}

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
