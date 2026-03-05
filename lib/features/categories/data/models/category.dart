import '../dtos/category_response_dto.dart';

class CategorySubcategory {
  const CategorySubcategory({required this.id, required this.name});

  final int id;
  final String name;

  factory CategorySubcategory.fromDto(SubcategoryItemResponseDto dto) =>
      CategorySubcategory(id: dto.id, name: dto.name);
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  final int id;
  final String name;
  final List<CategorySubcategory> subcategories;

  factory Category.fromDto(CategoryItemResponseDto dto) => Category(
        id: dto.id,
        name: dto.name,
        subcategories:
            dto.subCategories.map(CategorySubcategory.fromDto).toList(),
      );
}
