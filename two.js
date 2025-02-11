const crypto = require('crypto');
function sha256Hash(data) {
    return crypto.createHash('sha256').update(data).digest('hex');
}
function getHash(data){
    let nonce = 0;
    const now = Date.now();
    while(true){
        const res = sha256Hash('林华生' + nonce);
        if(res.startsWith(data)){
            console.log(`哈希值：${res}`)

            return ('林华生' + nonce)
        }
        nonce++
    }
}
const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
    modulusLength: 2048,
    publicKeyEncoding: { type: 'spki', format: 'pem' },
    privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
})


const res = getHash('0000')
console.log(res)

function signWithPrivateKey(privateKey, message) {
    const sign = crypto.createSign("sha256");
    sign.update(message);
    sign.end();
    return sign.sign(privateKey, "base64"); // 生成 Base64 编码的签名
}

const signature = signWithPrivateKey(privateKey, res);
console.log("Signature:", signature);


function verifyWithPublicKey(publicKey, message, signature) {
    console.log("验证哈希:",signature)
    const verify = crypto.createVerify("sha256");
    verify.update(message);
    verify.end();
    return verify.verify(publicKey, signature, "base64");
}

const isValid = verifyWithPublicKey(publicKey, res, signature);
console.log("验证结果:", isValid);

