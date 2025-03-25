// src/setupProxy.js
const { createProxyMiddleware } = require('http-proxy-middleware');

module.exports = function(app) {
  app.use(
    '/api',
    createProxyMiddleware({
      target: 'http://localhost:9001',
      changeOrigin: true,
      pathRewrite: {
        '^/api': '', // Remove o prefixo /api ao enviar para o backend
      },
    })
  );
};