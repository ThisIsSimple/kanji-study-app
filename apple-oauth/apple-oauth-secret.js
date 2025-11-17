const jwt = require('jsonwebtoken');
const fs = require('fs');

// .p8 파일 읽기
const privateKey = fs.readFileSync('AuthKey_M6Y94Q96D5.p8', 'utf8');

const clientSecret = jwt.sign(
  {
    iss: 'L5PQRC8G5Q',  // Team ID
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 15777000,  // 6개월
    aud: 'https://appleid.apple.com',
    sub: 'space.cordelia273.konnakanji.signin'  // Services ID
  },
  privateKey,
  {
    algorithm: 'ES256',
    header: {
      alg: 'ES256',
      kid: 'ABC123DEFG'  // Key ID
    }
  }
);

console.log('Client Secret:', clientSecret);
