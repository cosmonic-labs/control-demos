use wasmcloud_component::http;

struct Component;

http::export!(Component);

impl http::Server for Component {
    fn handle(
        _request: http::IncomingRequest,
    ) -> http::Result<http::Response<impl http::OutgoingBody>> {
        Ok(http::Response::new("
        Hello from Cosmonic Control!
        Your deployment is now running a WebAssembly application with wasmCloud.
        
        To learn more about building your own WebAssembly applications, visit:
        
        https://wasmcloud.com/docs/tour/hello-world/
          \n"))
    }
}
