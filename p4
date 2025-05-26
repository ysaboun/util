Pour intercepter les erreurs 401 dans une `WKWebView` **et rafraîchir automatiquement le token OAuth2** côté Swift, tu peux compléter la solution avec les éléments suivants :

---

## **Étapes pour gérer l’erreur 401 et rafraîchir le token côté Swift**

---

### **1. SPA appelle Apigee via WebView avec token injecté**

(on l’a déjà géré avec `WKUserScript` dans `makeWebView()`)

---

### **2. Injecter un script JS pour capturer les erreurs 401**

Ajoute dans ton script injecté une interception des réponses `fetch` en erreur 401, et fais appel à Swift via `window.webkit.messageHandlers`.

#### Ajout dans le script injecté :

```js
// À ajouter à ton script existant
window.fetch = async function(input, init = {}) {
    init.headers = init.headers || {};
    init.headers['Authorization'] = 'Bearer ' + accessToken;

    const response = await originalFetch(input, init);
    if (response.status === 401) {
        window.webkit.messageHandlers.authExpired.postMessage("401");
    }
    return response;
};
```

---

### **3. Ajouter un message handler Swift côté iOS**

```swift
class ViewController: UIViewController, WKScriptMessageHandler {
    var webView: WKWebView!

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "authExpired", let body = message.body as? String, body == "401" {
            print("Access token expired — refreshing...")
            refreshTokenAndReload()
        }
    }

    func refreshTokenAndReload() {
        // Implémente ici ton flow de refresh OAuth2 (par ex. via refresh token, ou relancer ASWebAuthenticationSession)
        getNewAccessToken { newToken in
            DispatchQueue.main.async {
                // Détruire l’ancienne webView
                self.webView.removeFromSuperview()

                // Recréer une nouvelle webView avec le nouveau token
                self.webView = makeWebView(withAccessToken: newToken)
                self.view.addSubview(self.webView)
                self.webView.load(URLRequest(url: URL(string: "https://app.mondomain.fr")!))
            }
        }
    }
}
```

---

### **4. Ne pas oublier d’enregistrer le handler**

Quand tu construis ton `WKWebView`, ajoute ceci :

```swift
contentController.add(self, name: "authExpired")
```

---

### **5. Optionnel : protéger le token dans Swift**

Ne garde jamais le token en clair. Utilise le **Keychain** si tu as un refresh token, et rafraîche avec `PKCE` si tu n’en as pas.

---

## **Résumé du fonctionnement :**

* Tu injectes un token OAuth2 dans les appels API via JS (`fetch`, `XMLHttpRequest`).
* Si une réponse 401 est reçue, tu envoies un message à Swift (`authExpired`).
* Swift relance un flow OAuth2, récupère un nouveau token, puis **recrée la `WKWebView` avec le nouveau token injecté au démarrage.**
