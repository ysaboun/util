Excellent scénario. Tu veux gérer le cas suivant **grâce à Swift sans perdre l’action de l’utilisateur** dans la WebView :

---

## **Contexte utilisateur :**

1. L’utilisateur clique sur un bouton dans la **SPA (React)** affichée dans une `WKWebView`.
2. La SPA envoie une requête `POST` à Apigee (ex. : `POST https://api-staging.mondomain.fr/fr/sendData`)
3. Apigee répond avec `401 Unauthorized` (ex. : token expiré)
4. Swift intercepte via le JS injecté, récupère un nouveau token
5. **Tu veux ensuite que la même requête POST soit automatiquement rejouée, sans intervention de l’utilisateur**

---

## **Approche 100 % côté WebView avec Swift/JS : Rejouer le POST après refresh**

### **1. Côté JavaScript injecté, override `fetch()` avec logique de re-jouabilité**

```js
(function() {
    let accessToken = '<INITIAL_TOKEN>';

    window.__updateAccessToken = function(newToken) {
        accessToken = newToken;
    };

    const originalFetch = window.fetch;
    window.fetch = async function(input, init = {}) {
        init.headers = init.headers || {};
        init.headers['Authorization'] = 'Bearer ' + accessToken;

        const response = await originalFetch(input, init);
        if (response.status === 401) {
            // Mémoriser la requête pour la rejouer plus tard
            window.__lastFetchRequest = { input, init };
            // Appeler Swift pour refresh
            window.webkit.messageHandlers.authExpired.postMessage("401");
        }
        return response;
    };

    window.__replayLastRequest = async function() {
        if (window.__lastFetchRequest) {
            const { input, init } = window.__lastFetchRequest;
            init.headers = init.headers || {};
            init.headers['Authorization'] = 'Bearer ' + accessToken;
            return await originalFetch(input, init);
        }
        return null;
    };
})();
```

---

### **2. Côté Swift : après le `refreshToken`, rejoue la requête POST**

```swift
func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
    if message.name == "authExpired" {
        refreshToken { newToken in
            let jsUpdateToken = "window.__updateAccessToken('\(newToken)');"
            let jsReplay = "window.__replayLastRequest();"

            webView.evaluateJavaScript(jsUpdateToken) { _, _ in
                // Rejouer la requête automatiquement
                self.webView.evaluateJavaScript(jsReplay, completionHandler: nil)
            }
        }
    }
}
```

---

### **Avantages de cette approche :**

* L’utilisateur **ne perd pas son action** (le clic bouton POST)
* Aucun changement nécessaire dans la SPA
* Tu contrôles tout côté Swift + JS injecté
* Fonctionne aussi pour plusieurs actions similaires (tu peux stocker un tableau de requêtes)
