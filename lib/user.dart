class User{
  final int? id;
  final String name;
  final String email;

  User({this.id,required this.name,required this.email});
  Map<String ,dynamic> toMap() {
    return {
      'id' :id,
      'name' :name,
      'email' :email
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int,
      name: map['name'] as String,
      email: map['email'] as String,
    );
  }
}