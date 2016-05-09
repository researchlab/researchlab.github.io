---
title: "golang类型转换(指定精度/四舍五入)"
date: 2016-03-24 02:06:54
categories: golang
tags: [golang]
description: 
---

## 前言
`Go`的数据类型很多都需要显示转换才能使用,比如`string`转`float64`指定精度等。转换中常用到的第三方包为`strconv`和`math`包。
<!--more-->

## 整型转字符串
```golang
strconv.Itoa(i) //方法1
strconv.FormatInt(int64(i),10) //方法2
```

## 字符串转整型
```golang
strconv.Atoi(s) //方法1
strconv.ParseInt(s,10,0) //方法2
```

## bytes转float64
```golang
func bytesToFloat64(bytes []byte) float64 {
	bits := binary.LittleEndian.Uint64(bytes)
	return math.Float64frombits(bits)
}
```

## float64转bytes
```golang
func float64ToBytes(input float64) []byte {
	bits := math.Float64bits(input)
	bytes := make([]byte,8) //这里表示[]uint8, 所以用了 8
	binary.LittleEndian.PutUint64(bytes,bits)
	return bytes
}
```

## float64转string 
```golang
func FloatToStr(num float64, floatPartLen int) string {
	return strconv.FormatFloat(num,'f',floatPartLen,64) //这里64改为32，则表示float32
}
```

## string转float64
`string`转`float64` 这里有两种方法，都支持指定精度。** 注意：所有数字要在表现层显示最好转换为字符串传送给表现层，如果用于后端计算则转换为数字即可。比如：数字2.10 如果用保持5位数字精度显示： 那么 数字2.10 显示为：2.1, 而将2.10转换为字符串同时保持5位精度，则显示为: 2.10000。但是它们都是转换为了5位精度的，只是显示的时候，数字2.10000 直接显示为2.1了， 所以要显示精度则转换为字符串，要用于计算则转换为数字。**

方法1： 只支持指定精度 
```golang
func strToFloat64(str string, len int) float64 {
	lenstr := "%." + strconv.Itoa(len) + "f"
	value,_ := strconv.ParseFloat(str,64)
	nstr := fmt.Sprintf(lenstr,value)
	val,_ := strconv.ParseFloat(nstr,64)
	return val
}
```

方法2：支持指定精度，支持是否四舍五入
```golang
func strToFloat64Round(str string, prec int, round bool) float64 {
	f,_ := strconv.ParseFloat(str,64)
	return Precision(f,prec,round)
}

func Precision(f float64, prec int, round bool) float64 {
	pow10_n := math.Pow10(prec)
	if round {
		return math.Trunc(f + 0.5/pow10_n)*pow10_n) / pow10_n	
	}
	return math.Trunc((f)*pow10_n) / pow10_n
}
```
具体请参考[[示例代码](https://github.com/researchlab/golearning/blob/master/base/convert.go)]
