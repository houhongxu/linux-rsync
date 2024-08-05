var http=require('http')
var fs=require('fs')

var server=http.createServer((request,response)=>{
  console.log(request.headers)
  
  fs.appendFile('./volume/volume.txt','+1',(err)=>{
    if (err) {
      console.error(err);
    }else{
      console.log('write success')
    }	  
  })

  response.end('hello world')
})

server.listen(3000,()=>{
  console.log('server on 3000')
})


