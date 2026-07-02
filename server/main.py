import tornado.ioloop
import tornado.httpserver
import tornado.options

from settings import *


def main():
    if PARSE_COMMAND_LINE:
        tornado.options.parse_command_line()
    if enable_HTTPS:
        http_server = tornado.httpserver.HTTPServer(application, ssl_options={
            "certfile": SSL_CERTFILE,
            "keyfile": SSL_KEYFILE,
        })
        http_server.listen(SERVER_PORT)
        print("The server is running at https://127.0.0.1:%s" % SERVER_PORT)
    else:
        application.listen(SERVER_PORT)
        print("The server is running at http://127.0.0.1:%s" % SERVER_PORT)
    print("Quit the server with Control-C")

    tornado.ioloop.IOLoop.current().start()

if __name__ == "__main__":
    main()
