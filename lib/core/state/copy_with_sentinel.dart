/// Shared sentinel for `copyWith` methods that must distinguish "argument
/// omitted" from "explicitly set to null" on a nullable field. Controllers use
/// `Object? field = kUnchanged` as the default and
/// `identical(field, kUnchanged) ? this.field : field as T` in the body — so a
/// caller can clear a nullable field by passing `null`, while omitting it keeps
/// the current value.
///
/// One shared instance so the ~13 state controllers don't each redeclare a
/// private `const _unchanged = Object()`.
const Object kUnchanged = Object();
