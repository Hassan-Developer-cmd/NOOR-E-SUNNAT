{{flutter_js}}
{{flutter_build_config}}

// ── Cache-Busting: Append dynamic timestamp to prevent browser & service worker caching ──
const _buildTimestamp = Date.now();
if (window._flutter && window._flutter.buildConfig && Array.isArray(window._flutter.buildConfig.builds)) {
  window._flutter.buildConfig.builds.forEach(function(build) {
    if (build.mainJsPath) {
      build.mainJsPath = build.mainJsPath + '?v=' + _buildTimestamp;
    }
  });
}

// ── Force load with null service worker & dynamic entrypoint ──
_flutter.loader.load({
  serviceWorkerSettings: null,
  config: {
    entrypointUrl: 'main.dart.js?v=' + _buildTimestamp
  }
});
