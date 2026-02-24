/// Web implementation of Google Sign-In using GIS SDK directly.
/// Dynamically loads the GIS SDK script, then uses renderButton in an overlay.
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

Completer<String?>? _activeCompleter;

/// Triggers Google Sign-In via GIS renderButton in an overlay.
/// Returns the credential JWT (idToken) or null if cancelled.
Future<String?> googleSignInWeb() async {
  final completer = Completer<String?>();
  _activeCompleter = completer;

  // Register Dart callbacks on window
  globalContext.setProperty(
    '_dartGsiOnCredential'.toJS,
    ((JSString token) {
      if (!completer.isCompleted) completer.complete(token.toDart);
    }).toJS,
  );

  globalContext.setProperty(
    '_dartGsiOnCancel'.toJS,
    (() {
      if (!completer.isCompleted) completer.complete(null);
    }).toJS,
  );

  // Execute everything in JS — including dynamic SDK loading
  globalContext.callMethod(
    'eval'.toJS,
    r'''
(function() {
  function doGsi() {
    if (typeof google === "undefined" || !google.accounts || !google.accounts.id) {
      console.error("[GSI] GIS SDK still not available after loading");
      window._dartGsiOnCancel();
      return;
    }

    // Remove existing overlay
    var old = document.getElementById("gsi-overlay");
    if (old) old.remove();

    // Create overlay
    var overlay = document.createElement("div");
    overlay.id = "gsi-overlay";
    overlay.style.cssText = "position:fixed;top:0;left:0;width:100vw;height:100vh;background:rgba(0,0,0,0.7);display:flex;align-items:center;justify-content:center;z-index:99999;";

    var box = document.createElement("div");
    box.style.cssText = "background:#1a1a1f;border-radius:16px;padding:32px;text-align:center;min-width:300px;";

    var title = document.createElement("p");
    title.textContent = "\u9078\u64C7 Google \u5E33\u865F\u767B\u5165";
    title.style.cssText = "color:#fff;font-size:16px;margin:0 0 20px 0;";
    box.appendChild(title);

    var btnDiv = document.createElement("div");
    btnDiv.id = "gsi-btn-container";
    box.appendChild(btnDiv);

    var cancel = document.createElement("button");
    cancel.textContent = "\u53D6\u6D88";
    cancel.style.cssText = "margin-top:16px;background:none;border:none;color:#888;font-size:14px;cursor:pointer;";
    cancel.onclick = function() {
      overlay.remove();
      window._dartGsiOnCancel();
    };
    box.appendChild(cancel);

    overlay.onclick = function(e) {
      if (e.target === overlay) {
        overlay.remove();
        window._dartGsiOnCancel();
      }
    };

    overlay.appendChild(box);
    document.body.appendChild(overlay);

    google.accounts.id.initialize({
      client_id: "315860625911-d94mos54u50nsv7tkbb888obdlrqbabs.apps.googleusercontent.com",
      callback: function(response) {
        overlay.remove();
        if (response && response.credential) {
          window._dartGsiOnCredential(response.credential);
        } else {
          window._dartGsiOnCancel();
        }
      }
    });

    google.accounts.id.renderButton(btnDiv, {
      theme: "filled_black",
      size: "large",
      width: 280,
      text: "signin_with"
    });
  }

  // Check if GIS SDK is already loaded
  if (typeof google !== "undefined" && google.accounts && google.accounts.id) {
    doGsi();
    return;
  }

  // Dynamically load the GIS SDK
  console.log("[GSI] Loading GIS SDK dynamically...");
  var script = document.createElement("script");
  script.src = "https://accounts.google.com/gsi/client";
  script.onload = function() {
    console.log("[GSI] GIS SDK loaded successfully");
    doGsi();
  };
  script.onerror = function() {
    console.error("[GSI] Failed to load GIS SDK script");
    window._dartGsiOnCancel();
  };
  document.head.appendChild(script);
})();
'''
        .toJS,
  );

  // Timeout after 120 seconds
  Future.delayed(const Duration(seconds: 120), () {
    if (!completer.isCompleted) {
      globalContext.callMethod(
        'eval'.toJS,
        'var o=document.getElementById("gsi-overlay");if(o)o.remove();'.toJS,
      );
      completer.complete(null);
    }
  });

  return completer.future;
}
