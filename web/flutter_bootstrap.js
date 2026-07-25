// This file is the Flutter web entrypoint.
'use strict';
const _flutter = {
  loader: null,
};

// Bootstrap Flutter
{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});
