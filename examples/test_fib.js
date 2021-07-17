/* example of JS module importing a C module */
import { fib } from "./libfib.so";

console.log("Hello World");
console.log("fib(10)=", fib(10));
