// This file patches the webpack dev server configuration
// to fix the allowedHosts issue on Windows

const fs = require('fs');
const path = require('path');

const configPath = path.join(__dirname, 'node_modules', 'react-scripts', 'config', 'webpackDevServer.config.js');

if (fs.existsSync(configPath)) {
  let config = fs.readFileSync(configPath, 'utf8');
  
  // Find the allowedHosts configuration and fix it
  config = config.replace(
    /allowedHosts:\s*\[/g,
    'allowedHosts: [\n    "localhost",\n    "127.0.0.1",'
  );
  
  fs.writeFileSync(configPath, config, 'utf8');
  console.log('Patched webpack dev server config');
} else {
  console.log('Config file not found, skipping patch');
}
