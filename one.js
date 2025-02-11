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
            console.log(`耗费时间：${Date.now() - now}毫秒`)
            console.log(`哈希值：${res}`)
            console.log(`Hash 的内容：${'林华生' + nonce}`)
            break;
        }
        nonce++
    }
}

getHash('0000')
getHash('00000')