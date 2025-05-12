package com.example.poc_webview_sso

import android.net.http.SslError
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.webkit.*
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity

class WebViewActivity : AppCompatActivity() {
    private lateinit var webView: WebView
    private var currentToken = "valid_token" // Token initial

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_webview)

        webView = findViewById(R.id.webview)
        WebView.setWebContentsDebuggingEnabled(true)

        with(webView.settings) {
            javaScriptEnabled = true
            domStorageEnabled = true
            cacheMode = if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT)
                WebSettings.LOAD_NO_CACHE
            else
                WebSettings.LOAD_DEFAULT

            userAgentString =
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0 Safari/537.36"
            mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
        }

        webView.webChromeClient = WebChromeClient()
        webView.settings.blockNetworkLoads = false

        // Écouter les messages venant de JavaScript (via postMessage)
        //val webViewListener = WebViewJavascriptBridge(webView)

        webView.addJavascriptInterface(object {
            @JavascriptInterface
            fun onTokenExpired() {
                Log.d("WebViewActivity", "📨 Message JS reçu : token expiré")
                renewToken()
            }
        }, "AndroidBridge")

        webView.webViewClient = object : WebViewClient() {

            override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                return false
            }

            override fun onPageFinished(view: WebView?, url: String?) {
                super.onPageFinished(view, url)
                injectToken()
            }

            override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: WebResourceError?) {
                super.onReceivedError(view, request, error)
                Log.d("Kotlin", "Error: ${error?.description}")
            }

            override fun onReceivedSslError(view: WebView?, handler: SslErrorHandler?, error: SslError?) {
                handler?.proceed() // Ignore SSL errors
            }

            // Intercepter les erreurs HTTP 401
            override fun onReceivedHttpError(view: WebView?, request: WebResourceRequest?, errorResponse: WebResourceResponse?) {
                super.onReceivedHttpError(view, request, errorResponse)
                // Afficher le détail de errorResponse pour le diagnostic
                Log.d("Kotlin", "HTTP Error: ${errorResponse?.statusCode} - ${errorResponse?.reasonPhrase}")
                if (errorResponse?.statusCode == 401) {
                    // Logique de renouvellement du token
                    Log.d("WebViewActivity", "🔑 Token expiré, tentative de renouvellement")

                    // Appel à une fonction pour renouveler le token côté Kotlin
                    renewToken()
                }
            }
        }

        webView.loadUrl("https://10.0.2.2:3000/") // Charger l'URL de la SPA
    }

    // Fonction de renouvellement du token
    private fun renewToken() {
        // Logique pour renouveler le token (par exemple, via une requête réseau)
        val newToken = "nouveau-token"  // Ce token devrait être obtenu via une requête HTTP ou autre méthode

        // Une fois le token renouvelé, on l'injecte dans la WebView
        currentToken = newToken
        injectToken()
    }

    private fun injectToken() {
        val js = """
            window.postMessage({ type: 'ACCESS_TOKEN', token: '$currentToken' }, '*');
        """.trimIndent()

        runOnUiThread {
            webView.evaluateJavascript(js, null)
        }
    }
}
