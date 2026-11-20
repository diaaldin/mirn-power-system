const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 5050;
const filePath = path.join(__dirname, 'mirn_system_preview.html');

const server = http.createServer((req, res) => {
  if (req.url === '/' || req.url === '/mirn_system_preview.html') {
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(500, { 'Content-Type': 'text/plain; charset=utf-8' });
        res.end('Error loading HTML preview: ' + err.message);
        return;
      }
      res.writeHead(200, {
        'Content-Type': 'text/html; charset=utf-8',
        'Cache-Control': 'no-cache'
      });
      res.end(data);
    });
  } else {
    // Attempt to serve static files if any requested
    const target = path.join(__dirname, decodeURIComponent(req.url.split('?')[0]));
    if (fs.existsSync(target) && fs.statSync(target).isFile()) {
      fs.createReadStream(target).pipe(res);
    } else {
      res.writeHead(302, { 'Location': '/' });
      res.end();
    }
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server started successfully on http://localhost:${PORT}`);
});
