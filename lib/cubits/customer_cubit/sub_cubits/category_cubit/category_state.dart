
abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {} // No data passed here

class CategoryEmpty extends CategoryState {}

class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}