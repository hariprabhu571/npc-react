   <?php
   header('Access-Control-Allow-Origin: http://localhost:3000');
   header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
   header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, Session-ID, session-id');
   header('Access-Control-Max-Age: 86400');
   if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
       http_response_code(200);
       exit();
   }
   echo 'CORS test OK';