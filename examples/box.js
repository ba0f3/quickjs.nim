console.log(Box);

box.name = "hello"

console.log("box", JSON.stringify(box));
console.log("width", box.width, "height", box.height, "area", box.area());

console.log(box.contains);
box.contains.push(4);
console.log(box.contains);

var box2 = new Box("Box2", 4, 6);
box2.contains.push(1);
console.log(box2.contains);
console.log("width", box2.width, "height", box2.height, "area", box2.area());
console.log("box2", JSON.stringify(box2));