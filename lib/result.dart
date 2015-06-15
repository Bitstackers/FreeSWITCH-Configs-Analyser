library ParseModel;

class Result<T> {
  List<String> errors = new List<String>();
  bool get IsValid => errors.isEmpty;
  T result;
}
