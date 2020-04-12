package main

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"fmt"
	"net/url"
	"os"
	"time"
)

func sign(secret string) string {
	timeStamp := fmt.Sprintf("%d", time.Now().UnixNano()/1e6)
	strToHash := fmt.Sprintf("%s\n%s", timeStamp, secret)
	hmac256 := hmac.New(sha256.New, []byte(secret))
	hmac256.Write([]byte(strToHash))
	signed := base64.StdEncoding.EncodeToString(hmac256.Sum(nil))
	urlencoded := url.QueryEscape(signed)
	return fmt.Sprintf("&timestamp=%s&sign=%s", timeStamp, urlencoded)
}

func main() {
//	fmt.Printf("secret is %s\n", os.Args[1])
	fmt.Println(sign(os.Args[1]))
}