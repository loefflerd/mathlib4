/-
Copyright (c) 2014 Jeremy Avigad. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jeremy Avigad, Leonardo de Moura
-/
import Mathlib.Data.Set.Operations
import Mathlib.Order.Basic
import Mathlib.Order.BooleanAlgebra
import Mathlib.Tactic.Tauto
import Mathlib.Tactic.ByContra
import Mathlib.Util.Delaborators
import Mathlib.Tactic.Lift

/-!
# Basic properties of sets

Sets in Lean are homogeneous; all their elements have the same type. Sets whose elements
have type `X` are thus defined as `Set X := X → Prop`. Note that this function need not
be decidable. The definition is in the module `Mathlib/Data/Set/Defs.lean`.

This file provides some basic definitions related to sets and functions not present in the
definitions file, as well as extra lemmas for functions defined in the definitions file and
`Mathlib/Data/Set/Operations.lean` (empty set, univ, union, intersection, insert, singleton,
set-theoretic difference, complement, and powerset).

Note that a set is a term, not a type. There is a coercion from `Set α` to `Type*` sending
`s` to the corresponding subtype `↥s`.

See also the file `SetTheory/ZFC.lean`, which contains an encoding of ZFC set theory in Lean.

## Main definitions

Notation used here:

-  `f : α → β` is a function,

-  `s : Set α` and `s₁ s₂ : Set α` are subsets of `α`

-  `t : Set β` is a subset of `β`.

Definitions in the file:

* `Nonempty s : Prop` : the predicate `s ≠ ∅`. Note that this is the preferred way to express the
  fact that `s` has an element (see the Implementation Notes).

* `inclusion s₁ s₂ : ↥s₁ → ↥s₂` : the map `↥s₁ → ↥s₂` induced by an inclusion `s₁ ⊆ s₂`.

## Notation

* `sᶜ` for the complement of `s`

## Implementation notes

* `s.Nonempty` is to be preferred to `s ≠ ∅` or `∃ x, x ∈ s`. It has the advantage that
  the `s.Nonempty` dot notation can be used.

* For `s : Set α`, do not use `Subtype s`. Instead use `↥s` or `(s : Type*)` or `s`.

## Tags

set, sets, subset, subsets, union, intersection, insert, singleton, complement, powerset

-/

assert_not_exists RelIso

/-! ### Set coercion to a type -/

open Function

universe u v

namespace Set

variable {α : Type u} {s t : Set α}

instance instBooleanAlgebra : BooleanAlgebra (Set α) :=
  { (inferInstance : BooleanAlgebra (α → Prop)) with
    sup := (· ∪ ·),
    le := (· ≤ ·),
    lt := fun s t => s ⊆ t ∧ ¬t ⊆ s,
    inf := (· ∩ ·),
    bot := ∅,
    compl := (·ᶜ),
    top := univ,
    sdiff := (· \ ·) }

instance : HasSSubset (Set α) :=
  ⟨(· < ·)⟩

@[simp]
theorem top_eq_univ : (⊤ : Set α) = univ :=
  rfl

@[simp]
theorem bot_eq_empty : (⊥ : Set α) = ∅ :=
  rfl

@[simp]
theorem sup_eq_union : ((· ⊔ ·) : Set α → Set α → Set α) = (· ∪ ·) :=
  rfl

@[simp]
theorem inf_eq_inter : ((· ⊓ ·) : Set α → Set α → Set α) = (· ∩ ·) :=
  rfl

@[simp]
theorem le_eq_subset : ((· ≤ ·) : Set α → Set α → Prop) = (· ⊆ ·) :=
  rfl

@[simp]
theorem lt_eq_ssubset : ((· < ·) : Set α → Set α → Prop) = (· ⊂ ·) :=
  rfl

theorem le_iff_subset : s ≤ t ↔ s ⊆ t :=
  Iff.rfl

theorem lt_iff_ssubset : s < t ↔ s ⊂ t :=
  Iff.rfl

alias ⟨_root_.LE.le.subset, _root_.HasSubset.Subset.le⟩ := le_iff_subset

alias ⟨_root_.LT.lt.ssubset, _root_.HasSSubset.SSubset.lt⟩ := lt_iff_ssubset

instance PiSetCoe.canLift (ι : Type u) (α : ι → Type v) [∀ i, Nonempty (α i)] (s : Set ι) :
    CanLift (∀ i : s, α i) (∀ i, α i) (fun f i => f i) fun _ => True :=
  PiSubtype.canLift ι α s

instance PiSetCoe.canLift' (ι : Type u) (α : Type v) [Nonempty α] (s : Set ι) :
    CanLift (s → α) (ι → α) (fun f i => f i) fun _ => True :=
  PiSetCoe.canLift ι (fun _ => α) s

end Set

section SetCoe

variable {α : Type u}

instance (s : Set α) : CoeTC s α := ⟨fun x => x.1⟩

theorem Set.coe_eq_subtype (s : Set α) : ↥s = { x // x ∈ s } :=
  rfl

@[simp]
theorem Set.coe_setOf (p : α → Prop) : ↥{ x | p x } = { x // p x } :=
  rfl

theorem SetCoe.forall {s : Set α} {p : s → Prop} : (∀ x : s, p x) ↔ ∀ (x) (h : x ∈ s), p ⟨x, h⟩ :=
  Subtype.forall

theorem SetCoe.exists {s : Set α} {p : s → Prop} :
    (∃ x : s, p x) ↔ ∃ (x : _) (h : x ∈ s), p ⟨x, h⟩ :=
  Subtype.exists

theorem SetCoe.exists' {s : Set α} {p : ∀ x, x ∈ s → Prop} :
    (∃ (x : _) (h : x ∈ s), p x h) ↔ ∃ x : s, p x.1 x.2 :=
  (@SetCoe.exists _ _ fun x => p x.1 x.2).symm

theorem SetCoe.forall' {s : Set α} {p : ∀ x, x ∈ s → Prop} :
    (∀ (x) (h : x ∈ s), p x h) ↔ ∀ x : s, p x.1 x.2 :=
  (@SetCoe.forall _ _ fun x => p x.1 x.2).symm

@[simp]
theorem set_coe_cast :
    ∀ {s t : Set α} (H' : s = t) (H : ↥s = ↥t) (x : s), cast H x = ⟨x.1, H' ▸ x.2⟩
  | _, _, rfl, _, _ => rfl

theorem SetCoe.ext {s : Set α} {a b : s} : (a : α) = b → a = b :=
  Subtype.eq

theorem SetCoe.ext_iff {s : Set α} {a b : s} : (↑a : α) = ↑b ↔ a = b :=
  Iff.intro SetCoe.ext fun h => h ▸ rfl

end SetCoe

/-- See also `Subtype.prop` -/
theorem Subtype.mem {α : Type*} {s : Set α} (p : s) : (p : α) ∈ s :=
  p.prop

/-- Duplicate of `Eq.subset'`, which currently has elaboration problems. -/
theorem Eq.subset {α} {s t : Set α} : s = t → s ⊆ t :=
  fun h₁ _ h₂ => by rw [← h₁]; exact h₂

namespace Set

variable {α : Type u} {β : Type v} {a b : α} {s s₁ s₂ t t₁ t₂ u : Set α}

instance : Inhabited (Set α) :=
  ⟨∅⟩

@[trans]
theorem mem_of_mem_of_subset {x : α} {s t : Set α} (hx : x ∈ s) (h : s ⊆ t) : x ∈ t :=
  h hx

@[deprecated forall_swap (since := "2025-06-10")]
theorem forall_in_swap {p : α → β → Prop} : (∀ a ∈ s, ∀ (b), p a b) ↔ ∀ (b), ∀ a ∈ s, p a b := by
  tauto

theorem setOf_injective : Function.Injective (@setOf α) := injective_id

theorem setOf_inj {p q : α → Prop} : { x | p x } = { x | q x } ↔ p = q := Iff.rfl

/-! ### Lemmas about `mem` and `setOf` -/

@[deprecated "This lemma abuses the `Set α := α → Prop` defeq.
If you think you need it you have already taken a wrong turn." (since := "2025-06-10")]
theorem setOf_set {s : Set α} : setOf s = s :=
  rfl

@[deprecated "This lemma abuses the `Set α := α → Prop` defeq.
If you think you need it you have already taken a wrong turn." (since := "2025-06-10")]
theorem setOf_app_iff {p : α → Prop} {x : α} : { x | p x } x ↔ p x :=
  Iff.rfl

@[deprecated "This lemma abuses the `Set α := α → Prop` defeq.
If you think you need it you have already taken a wrong turn." (since := "2025-06-10")]
theorem mem_def {a : α} {s : Set α} : a ∈ s ↔ s a :=
  Iff.rfl

theorem setOf_bijective : Bijective (setOf : (α → Prop) → Set α) :=
  bijective_id

theorem subset_setOf {p : α → Prop} {s : Set α} : s ⊆ setOf p ↔ ∀ x, x ∈ s → p x :=
  Iff.rfl

theorem setOf_subset {p : α → Prop} {s : Set α} : setOf p ⊆ s ↔ ∀ x, p x → x ∈ s :=
  Iff.rfl

@[simp]
theorem setOf_subset_setOf {p q : α → Prop} : { a | p a } ⊆ { a | q a } ↔ ∀ a, p a → q a :=
  Iff.rfl

@[gcongr]
alias ⟨_, setOf_subset_setOf_of_imp⟩ := setOf_subset_setOf

theorem setOf_and {p q : α → Prop} : { a | p a ∧ q a } = { a | p a } ∩ { a | q a } :=
  rfl

theorem setOf_or {p q : α → Prop} : { a | p a ∨ q a } = { a | p a } ∪ { a | q a } :=
  rfl

/-! ### Subset and strict subset relations -/


instance : IsRefl (Set α) (· ⊆ ·) :=
  show IsRefl (Set α) (· ≤ ·) by infer_instance

instance : IsTrans (Set α) (· ⊆ ·) :=
  show IsTrans (Set α) (· ≤ ·) by infer_instance

instance : Trans ((· ⊆ ·) : Set α → Set α → Prop) (· ⊆ ·) (· ⊆ ·) :=
  show Trans (· ≤ ·) (· ≤ ·) (· ≤ ·) by infer_instance

instance : IsAntisymm (Set α) (· ⊆ ·) :=
  show IsAntisymm (Set α) (· ≤ ·) by infer_instance

instance : IsIrrefl (Set α) (· ⊂ ·) :=
  show IsIrrefl (Set α) (· < ·) by infer_instance

instance : IsTrans (Set α) (· ⊂ ·) :=
  show IsTrans (Set α) (· < ·) by infer_instance

instance : Trans ((· ⊂ ·) : Set α → Set α → Prop) (· ⊂ ·) (· ⊂ ·) :=
  show Trans (· < ·) (· < ·) (· < ·) by infer_instance

instance : Trans ((· ⊂ ·) : Set α → Set α → Prop) (· ⊆ ·) (· ⊂ ·) :=
  show Trans (· < ·) (· ≤ ·) (· < ·) by infer_instance

instance : Trans ((· ⊆ ·) : Set α → Set α → Prop) (· ⊂ ·) (· ⊂ ·) :=
  show Trans (· ≤ ·) (· < ·) (· < ·) by infer_instance

instance : IsAsymm (Set α) (· ⊂ ·) :=
  show IsAsymm (Set α) (· < ·) by infer_instance

instance : IsNonstrictStrictOrder (Set α) (· ⊆ ·) (· ⊂ ·) :=
  ⟨fun _ _ => Iff.rfl⟩

-- TODO(Jeremy): write a tactic to unfold specific instances of generic notation?
theorem subset_def : (s ⊆ t) = ∀ x, x ∈ s → x ∈ t :=
  rfl

theorem ssubset_def : (s ⊂ t) = (s ⊆ t ∧ ¬t ⊆ s) :=
  rfl

@[refl]
theorem Subset.refl (a : Set α) : a ⊆ a := fun _ => id

theorem Subset.rfl {s : Set α} : s ⊆ s :=
  Subset.refl s

@[trans]
theorem Subset.trans {a b c : Set α} (ab : a ⊆ b) (bc : b ⊆ c) : a ⊆ c := fun _ h => bc <| ab h

@[trans]
theorem mem_of_eq_of_mem {x y : α} {s : Set α} (hx : x = y) (h : y ∈ s) : x ∈ s :=
  hx.symm ▸ h

theorem Subset.antisymm {a b : Set α} (h₁ : a ⊆ b) (h₂ : b ⊆ a) : a = b :=
  Set.ext fun _ => ⟨@h₁ _, @h₂ _⟩

theorem Subset.antisymm_iff {a b : Set α} : a = b ↔ a ⊆ b ∧ b ⊆ a :=
  ⟨fun e => ⟨e.subset, e.symm.subset⟩, fun ⟨h₁, h₂⟩ => Subset.antisymm h₁ h₂⟩

-- an alternative name
theorem eq_of_subset_of_subset {a b : Set α} : a ⊆ b → b ⊆ a → a = b :=
  Subset.antisymm

@[gcongr] theorem mem_of_subset_of_mem {s₁ s₂ : Set α} {a : α} (h : s₁ ⊆ s₂) : a ∈ s₁ → a ∈ s₂ :=
  @h _

theorem notMem_subset (h : s ⊆ t) : a ∉ t → a ∉ s :=
  mt <| mem_of_subset_of_mem h

@[deprecated (since := "2025-05-23")] alias not_mem_subset := notMem_subset

theorem not_subset : ¬s ⊆ t ↔ ∃ a ∈ s, a ∉ t := by
  simp only [subset_def, not_forall, exists_prop]

theorem not_top_subset : ¬⊤ ⊆ s ↔ ∃ a, a ∉ s := by
  simp [not_subset]

lemma eq_of_forall_subset_iff (h : ∀ u, s ⊆ u ↔ t ⊆ u) : s = t := eq_of_forall_ge_iff h

/-! ### Definition of strict subsets `s ⊂ t` and basic properties. -/

protected theorem eq_or_ssubset_of_subset (h : s ⊆ t) : s = t ∨ s ⊂ t :=
  eq_or_lt_of_le h

theorem exists_of_ssubset {s t : Set α} (h : s ⊂ t) : ∃ x ∈ t, x ∉ s :=
  not_subset.1 h.2

protected theorem ssubset_iff_subset_ne {s t : Set α} : s ⊂ t ↔ s ⊆ t ∧ s ≠ t :=
  @lt_iff_le_and_ne (Set α) _ s t

theorem ssubset_iff_of_subset {s t : Set α} (h : s ⊆ t) : s ⊂ t ↔ ∃ x ∈ t, x ∉ s :=
  ⟨exists_of_ssubset, fun ⟨_, hxt, hxs⟩ => ⟨h, fun h => hxs <| h hxt⟩⟩

theorem ssubset_iff_exists {s t : Set α} : s ⊂ t ↔ s ⊆ t ∧ ∃ x ∈ t, x ∉ s :=
  ⟨fun h ↦ ⟨h.le, Set.exists_of_ssubset h⟩, fun ⟨h1, h2⟩ ↦ (Set.ssubset_iff_of_subset h1).mpr h2⟩

protected theorem ssubset_of_ssubset_of_subset {s₁ s₂ s₃ : Set α} (hs₁s₂ : s₁ ⊂ s₂)
    (hs₂s₃ : s₂ ⊆ s₃) : s₁ ⊂ s₃ :=
  ⟨Subset.trans hs₁s₂.1 hs₂s₃, fun hs₃s₁ => hs₁s₂.2 (Subset.trans hs₂s₃ hs₃s₁)⟩

protected theorem ssubset_of_subset_of_ssubset {s₁ s₂ s₃ : Set α} (hs₁s₂ : s₁ ⊆ s₂)
    (hs₂s₃ : s₂ ⊂ s₃) : s₁ ⊂ s₃ :=
  ⟨Subset.trans hs₁s₂ hs₂s₃.1, fun hs₃s₁ => hs₂s₃.2 (Subset.trans hs₃s₁ hs₁s₂)⟩

theorem notMem_empty (x : α) : x ∉ (∅ : Set α) :=
  id

@[deprecated (since := "2025-05-23")] alias not_mem_empty := notMem_empty

theorem not_notMem : ¬a ∉ s ↔ a ∈ s :=
  not_not

@[deprecated (since := "2025-05-23")] alias not_not_mem := not_notMem

/-! ### Non-empty sets -/

theorem nonempty_coe_sort {s : Set α} : Nonempty ↥s ↔ s.Nonempty :=
  nonempty_subtype

alias ⟨_, Nonempty.coe_sort⟩ := nonempty_coe_sort

theorem nonempty_def : s.Nonempty ↔ ∃ x, x ∈ s :=
  Iff.rfl

theorem nonempty_of_mem {x} (h : x ∈ s) : s.Nonempty :=
  ⟨x, h⟩

theorem Nonempty.not_subset_empty : s.Nonempty → ¬s ⊆ ∅
  | ⟨_, hx⟩, hs => hs hx

/-- Extract a witness from `s.Nonempty`. This function might be used instead of case analysis
on the argument. Note that it makes a proof depend on the `Classical.choice` axiom. -/
protected noncomputable def Nonempty.some (h : s.Nonempty) : α :=
  Classical.choose h

protected theorem Nonempty.some_mem (h : s.Nonempty) : h.some ∈ s :=
  Classical.choose_spec h

@[gcongr] theorem Nonempty.mono (ht : s ⊆ t) (hs : s.Nonempty) : t.Nonempty :=
  hs.imp ht

theorem nonempty_of_not_subset (h : ¬s ⊆ t) : (s \ t).Nonempty :=
  let ⟨x, xs, xt⟩ := not_subset.1 h
  ⟨x, xs, xt⟩

theorem nonempty_of_ssubset (ht : s ⊂ t) : (t \ s).Nonempty :=
  nonempty_of_not_subset ht.2

theorem Nonempty.of_diff (h : (s \ t).Nonempty) : s.Nonempty :=
  h.imp fun _ => And.left

theorem nonempty_of_ssubset' (ht : s ⊂ t) : t.Nonempty :=
  (nonempty_of_ssubset ht).of_diff

theorem Nonempty.inl (hs : s.Nonempty) : (s ∪ t).Nonempty :=
  hs.imp fun _ => Or.inl

theorem Nonempty.inr (ht : t.Nonempty) : (s ∪ t).Nonempty :=
  ht.imp fun _ => Or.inr

@[simp]
theorem union_nonempty : (s ∪ t).Nonempty ↔ s.Nonempty ∨ t.Nonempty :=
  exists_or

theorem Nonempty.left (h : (s ∩ t).Nonempty) : s.Nonempty :=
  h.imp fun _ => And.left

theorem Nonempty.right (h : (s ∩ t).Nonempty) : t.Nonempty :=
  h.imp fun _ => And.right

theorem inter_nonempty : (s ∩ t).Nonempty ↔ ∃ x, x ∈ s ∧ x ∈ t :=
  Iff.rfl

theorem inter_nonempty_iff_exists_left : (s ∩ t).Nonempty ↔ ∃ x ∈ s, x ∈ t := by
  simp_rw [inter_nonempty]

theorem inter_nonempty_iff_exists_right : (s ∩ t).Nonempty ↔ ∃ x ∈ t, x ∈ s := by
  simp_rw [inter_nonempty, and_comm]

theorem nonempty_iff_univ_nonempty : Nonempty α ↔ (univ : Set α).Nonempty :=
  ⟨fun ⟨x⟩ => ⟨x, trivial⟩, fun ⟨x, _⟩ => ⟨x⟩⟩

@[simp]
theorem univ_nonempty : ∀ [Nonempty α], (univ : Set α).Nonempty
  | ⟨x⟩ => ⟨x, trivial⟩

theorem Nonempty.to_subtype : s.Nonempty → Nonempty (↥s) :=
  nonempty_subtype.2

theorem Nonempty.to_type : s.Nonempty → Nonempty α := fun ⟨x, _⟩ => ⟨x⟩

instance univ.nonempty [Nonempty α] : Nonempty (↥(Set.univ : Set α)) :=
  Set.univ_nonempty.to_subtype

-- Redeclare for refined keys
-- `Nonempty (@Subtype _ (@Membership.mem _ (Set _) _ (@Top.top (Set _) _)))`
instance instNonemptyTop [Nonempty α] : Nonempty (⊤ : Set α) :=
  inferInstanceAs (Nonempty (univ : Set α))

theorem Nonempty.of_subtype [Nonempty (↥s)] : s.Nonempty := nonempty_subtype.mp ‹_›

@[deprecated (since := "2024-11-23")] alias nonempty_of_nonempty_subtype := Nonempty.of_subtype

/-! ### Lemmas about the empty set -/

theorem empty_def : (∅ : Set α) = { _x : α | False } :=
  rfl

@[simp]
theorem mem_empty_iff_false (x : α) : x ∈ (∅ : Set α) ↔ False :=
  Iff.rfl

@[simp]
theorem setOf_false : { _a : α | False } = ∅ :=
  rfl

@[simp] theorem setOf_bot : { _x : α | ⊥ } = ∅ := rfl

@[simp]
theorem empty_subset (s : Set α) : ∅ ⊆ s :=
  nofun

@[simp]
theorem subset_empty_iff {s : Set α} : s ⊆ ∅ ↔ s = ∅ :=
  (Subset.antisymm_iff.trans <| and_iff_left (empty_subset _)).symm

theorem eq_empty_iff_forall_notMem {s : Set α} : s = ∅ ↔ ∀ x, x ∉ s :=
  subset_empty_iff.symm

@[deprecated (since := "2025-05-23")]
alias eq_empty_iff_forall_not_mem := eq_empty_iff_forall_notMem

theorem eq_empty_of_forall_notMem (h : ∀ x, x ∉ s) : s = ∅ :=
  subset_empty_iff.1 h

@[deprecated (since := "2025-05-23")] alias eq_empty_of_forall_not_mem := eq_empty_of_forall_notMem

theorem eq_empty_of_subset_empty {s : Set α} : s ⊆ ∅ → s = ∅ :=
  subset_empty_iff.1

theorem eq_empty_of_isEmpty [IsEmpty α] (s : Set α) : s = ∅ :=
  eq_empty_of_subset_empty fun x _ => isEmptyElim x

/-- There is exactly one set of a type that is empty. -/
instance uniqueEmpty [IsEmpty α] : Unique (Set α) where
  default := ∅
  uniq := eq_empty_of_isEmpty

/-- See also `Set.nonempty_iff_ne_empty`. -/
theorem not_nonempty_iff_eq_empty {s : Set α} : ¬s.Nonempty ↔ s = ∅ := by
  simp only [Set.Nonempty, not_exists, eq_empty_iff_forall_notMem]

/-- See also `Set.not_nonempty_iff_eq_empty`. -/
theorem nonempty_iff_ne_empty : s.Nonempty ↔ s ≠ ∅ :=
  not_nonempty_iff_eq_empty.not_right

/-- See also `nonempty_iff_ne_empty'`. -/
theorem not_nonempty_iff_eq_empty' : ¬Nonempty s ↔ s = ∅ := by
  rw [nonempty_subtype, not_exists, eq_empty_iff_forall_notMem]

/-- See also `not_nonempty_iff_eq_empty'`. -/
theorem nonempty_iff_ne_empty' : Nonempty s ↔ s ≠ ∅ :=
  not_nonempty_iff_eq_empty'.not_right

alias ⟨Nonempty.ne_empty, _⟩ := nonempty_iff_ne_empty

@[simp]
theorem not_nonempty_empty : ¬(∅ : Set α).Nonempty := fun ⟨_, hx⟩ => hx

@[simp]
theorem isEmpty_coe_sort {s : Set α} : IsEmpty (↥s) ↔ s = ∅ :=
  not_iff_not.1 <| by simpa using nonempty_iff_ne_empty

theorem eq_empty_or_nonempty (s : Set α) : s = ∅ ∨ s.Nonempty :=
  or_iff_not_imp_left.2 nonempty_iff_ne_empty.2

theorem subset_eq_empty {s t : Set α} (h : t ⊆ s) (e : s = ∅) : t = ∅ :=
  subset_empty_iff.1 <| e ▸ h

theorem forall_mem_empty {p : α → Prop} : (∀ x ∈ (∅ : Set α), p x) ↔ True :=
  iff_true_intro fun _ => False.elim

instance (α : Type u) : IsEmpty.{u + 1} (↥(∅ : Set α)) :=
  ⟨fun x => x.2⟩

@[simp]
theorem empty_ssubset : ∅ ⊂ s ↔ s.Nonempty :=
  (@bot_lt_iff_ne_bot (Set α) _ _ _).trans nonempty_iff_ne_empty.symm

alias ⟨_, Nonempty.empty_ssubset⟩ := empty_ssubset

/-!

### Universal set.

In Lean `@univ α` (or `univ : Set α`) is the set that contains all elements of type `α`.
Mathematically it is the same as `α` but it has a different type.

-/


@[simp]
theorem setOf_true : { _x : α | True } = univ :=
  rfl

@[simp] theorem setOf_top : { _x : α | ⊤ } = univ := rfl

@[simp]
theorem univ_eq_empty_iff : (univ : Set α) = ∅ ↔ IsEmpty α :=
  eq_empty_iff_forall_notMem.trans
    ⟨fun H => ⟨fun x => H x trivial⟩, fun H x _ => @IsEmpty.false α H x⟩

theorem empty_ne_univ [Nonempty α] : (∅ : Set α) ≠ univ := fun e =>
  not_isEmpty_of_nonempty α <| univ_eq_empty_iff.1 e.symm

@[simp]
theorem subset_univ (s : Set α) : s ⊆ univ := fun _ _ => trivial

@[simp]
theorem univ_subset_iff {s : Set α} : univ ⊆ s ↔ s = univ :=
  @top_le_iff _ _ _ s

alias ⟨eq_univ_of_univ_subset, _⟩ := univ_subset_iff

theorem eq_univ_iff_forall {s : Set α} : s = univ ↔ ∀ x, x ∈ s :=
  univ_subset_iff.symm.trans <| forall_congr' fun _ => imp_iff_right trivial

theorem eq_univ_of_forall {s : Set α} : (∀ x, x ∈ s) → s = univ :=
  eq_univ_iff_forall.2

theorem Nonempty.eq_univ [Subsingleton α] : s.Nonempty → s = univ := by
  rintro ⟨x, hx⟩
  exact eq_univ_of_forall fun y => by rwa [Subsingleton.elim y x]

theorem eq_univ_of_subset {s t : Set α} (h : s ⊆ t) (hs : s = univ) : t = univ :=
  eq_univ_of_univ_subset <| (hs ▸ h : univ ⊆ t)

theorem exists_mem_of_nonempty (α) : ∀ [Nonempty α], ∃ x : α, x ∈ (univ : Set α)
  | ⟨x⟩ => ⟨x, trivial⟩

theorem ne_univ_iff_exists_notMem {α : Type*} (s : Set α) : s ≠ univ ↔ ∃ a, a ∉ s := by
  rw [← not_forall, ← eq_univ_iff_forall]

@[deprecated (since := "2025-05-23")] alias ne_univ_iff_exists_not_mem := ne_univ_iff_exists_notMem

theorem not_subset_iff_exists_mem_notMem {α : Type*} {s t : Set α} :
    ¬s ⊆ t ↔ ∃ x, x ∈ s ∧ x ∉ t := by simp [subset_def]

@[deprecated (since := "2025-05-23")]
alias not_subset_iff_exists_mem_not_mem := not_subset_iff_exists_mem_notMem

theorem univ_unique [Unique α] : @Set.univ α = {default} :=
  Set.ext fun x => iff_of_true trivial <| Subsingleton.elim x default

theorem ssubset_univ_iff : s ⊂ univ ↔ s ≠ univ :=
  lt_top_iff_ne_top

instance nontrivial_of_nonempty [Nonempty α] : Nontrivial (Set α) :=
  ⟨⟨∅, univ, empty_ne_univ⟩⟩

/-! ### Lemmas about union -/

theorem union_def {s₁ s₂ : Set α} : s₁ ∪ s₂ = { a | a ∈ s₁ ∨ a ∈ s₂ } :=
  rfl

theorem mem_union_left {x : α} {a : Set α} (b : Set α) : x ∈ a → x ∈ a ∪ b :=
  Or.inl

theorem mem_union_right {x : α} {b : Set α} (a : Set α) : x ∈ b → x ∈ a ∪ b :=
  Or.inr

theorem mem_or_mem_of_mem_union {x : α} {a b : Set α} (H : x ∈ a ∪ b) : x ∈ a ∨ x ∈ b :=
  H

theorem MemUnion.elim {x : α} {a b : Set α} {P : Prop} (H₁ : x ∈ a ∪ b) (H₂ : x ∈ a → P)
    (H₃ : x ∈ b → P) : P :=
  Or.elim H₁ H₂ H₃

@[simp]
theorem mem_union (x : α) (a b : Set α) : x ∈ a ∪ b ↔ x ∈ a ∨ x ∈ b :=
  Iff.rfl

@[simp]
theorem union_self (a : Set α) : a ∪ a = a :=
  ext fun _ => or_self_iff

@[simp]
theorem union_empty (a : Set α) : a ∪ ∅ = a :=
  ext fun _ => iff_of_eq (or_false _)

@[simp]
theorem empty_union (a : Set α) : ∅ ∪ a = a :=
  ext fun _ => iff_of_eq (false_or _)

theorem union_comm (a b : Set α) : a ∪ b = b ∪ a :=
  ext fun _ => or_comm

theorem union_assoc (a b c : Set α) : a ∪ b ∪ c = a ∪ (b ∪ c) :=
  ext fun _ => or_assoc

instance union_isAssoc : Std.Associative (α := Set α) (· ∪ ·) :=
  ⟨union_assoc⟩

instance union_isComm : Std.Commutative (α := Set α) (· ∪ ·) :=
  ⟨union_comm⟩

theorem union_left_comm (s₁ s₂ s₃ : Set α) : s₁ ∪ (s₂ ∪ s₃) = s₂ ∪ (s₁ ∪ s₃) :=
  ext fun _ => or_left_comm

theorem union_right_comm (s₁ s₂ s₃ : Set α) : s₁ ∪ s₂ ∪ s₃ = s₁ ∪ s₃ ∪ s₂ :=
  ext fun _ => or_right_comm

@[simp]
theorem union_eq_left {s t : Set α} : s ∪ t = s ↔ t ⊆ s :=
  sup_eq_left

@[simp]
theorem union_eq_right {s t : Set α} : s ∪ t = t ↔ s ⊆ t :=
  sup_eq_right

theorem union_eq_self_of_subset_left {s t : Set α} (h : s ⊆ t) : s ∪ t = t :=
  union_eq_right.mpr h

theorem union_eq_self_of_subset_right {s t : Set α} (h : t ⊆ s) : s ∪ t = s :=
  union_eq_left.mpr h

@[simp]
theorem subset_union_left {s t : Set α} : s ⊆ s ∪ t := fun _ => Or.inl

@[simp]
theorem subset_union_right {s t : Set α} : t ⊆ s ∪ t := fun _ => Or.inr

theorem union_subset {s t r : Set α} (sr : s ⊆ r) (tr : t ⊆ r) : s ∪ t ⊆ r := fun _ =>
  Or.rec (@sr _) (@tr _)

@[simp]
theorem union_subset_iff {s t u : Set α} : s ∪ t ⊆ u ↔ s ⊆ u ∧ t ⊆ u :=
  (forall_congr' fun _ => or_imp).trans forall_and

@[gcongr]
theorem union_subset_union {s₁ s₂ t₁ t₂ : Set α} (h₁ : s₁ ⊆ s₂) (h₂ : t₁ ⊆ t₂) :
    s₁ ∪ t₁ ⊆ s₂ ∪ t₂ := fun _ => Or.imp (@h₁ _) (@h₂ _)

@[gcongr]
theorem union_subset_union_left {s₁ s₂ : Set α} (t) (h : s₁ ⊆ s₂) : s₁ ∪ t ⊆ s₂ ∪ t :=
  union_subset_union h Subset.rfl

@[gcongr]
theorem union_subset_union_right (s) {t₁ t₂ : Set α} (h : t₁ ⊆ t₂) : s ∪ t₁ ⊆ s ∪ t₂ :=
  union_subset_union Subset.rfl h

theorem subset_union_of_subset_left {s t : Set α} (h : s ⊆ t) (u : Set α) : s ⊆ t ∪ u :=
  h.trans subset_union_left

theorem subset_union_of_subset_right {s u : Set α} (h : s ⊆ u) (t : Set α) : s ⊆ t ∪ u :=
  h.trans subset_union_right

theorem union_congr_left (ht : t ⊆ s ∪ u) (hu : u ⊆ s ∪ t) : s ∪ t = s ∪ u :=
  sup_congr_left ht hu

theorem union_congr_right (hs : s ⊆ t ∪ u) (ht : t ⊆ s ∪ u) : s ∪ u = t ∪ u :=
  sup_congr_right hs ht

theorem union_eq_union_iff_left : s ∪ t = s ∪ u ↔ t ⊆ s ∪ u ∧ u ⊆ s ∪ t :=
  sup_eq_sup_iff_left

theorem union_eq_union_iff_right : s ∪ u = t ∪ u ↔ s ⊆ t ∪ u ∧ t ⊆ s ∪ u :=
  sup_eq_sup_iff_right

@[simp]
theorem union_empty_iff {s t : Set α} : s ∪ t = ∅ ↔ s = ∅ ∧ t = ∅ := by
  simp only [← subset_empty_iff]
  exact union_subset_iff

@[simp]
theorem union_univ (s : Set α) : s ∪ univ = univ := sup_top_eq _

@[simp]
theorem univ_union (s : Set α) : univ ∪ s = univ := top_sup_eq _

@[simp]
theorem ssubset_union_left_iff : s ⊂ s ∪ t ↔ ¬ t ⊆ s :=
  left_lt_sup

@[simp]
theorem ssubset_union_right_iff : t ⊂ s ∪ t ↔ ¬ s ⊆ t :=
  right_lt_sup

/-! ### Lemmas about intersection -/

theorem inter_def {s₁ s₂ : Set α} : s₁ ∩ s₂ = { a | a ∈ s₁ ∧ a ∈ s₂ } :=
  rfl

@[simp, mfld_simps]
theorem mem_inter_iff (x : α) (a b : Set α) : x ∈ a ∩ b ↔ x ∈ a ∧ x ∈ b :=
  Iff.rfl

theorem mem_inter {x : α} {a b : Set α} (ha : x ∈ a) (hb : x ∈ b) : x ∈ a ∩ b :=
  ⟨ha, hb⟩

theorem mem_of_mem_inter_left {x : α} {a b : Set α} (h : x ∈ a ∩ b) : x ∈ a :=
  h.left

theorem mem_of_mem_inter_right {x : α} {a b : Set α} (h : x ∈ a ∩ b) : x ∈ b :=
  h.right

@[simp]
theorem inter_self (a : Set α) : a ∩ a = a :=
  ext fun _ => and_self_iff

@[simp]
theorem inter_empty (a : Set α) : a ∩ ∅ = ∅ :=
  ext fun _ => iff_of_eq (and_false _)

@[simp]
theorem empty_inter (a : Set α) : ∅ ∩ a = ∅ :=
  ext fun _ => iff_of_eq (false_and _)

theorem inter_comm (a b : Set α) : a ∩ b = b ∩ a :=
  ext fun _ => and_comm

theorem inter_assoc (a b c : Set α) : a ∩ b ∩ c = a ∩ (b ∩ c) :=
  ext fun _ => and_assoc

instance inter_isAssoc : Std.Associative (α := Set α) (· ∩ ·) :=
  ⟨inter_assoc⟩

instance inter_isComm : Std.Commutative (α := Set α) (· ∩ ·) :=
  ⟨inter_comm⟩

theorem inter_left_comm (s₁ s₂ s₃ : Set α) : s₁ ∩ (s₂ ∩ s₃) = s₂ ∩ (s₁ ∩ s₃) :=
  ext fun _ => and_left_comm

theorem inter_right_comm (s₁ s₂ s₃ : Set α) : s₁ ∩ s₂ ∩ s₃ = s₁ ∩ s₃ ∩ s₂ :=
  ext fun _ => and_right_comm

@[simp, mfld_simps]
theorem inter_subset_left {s t : Set α} : s ∩ t ⊆ s := fun _ => And.left

@[simp]
theorem inter_subset_right {s t : Set α} : s ∩ t ⊆ t := fun _ => And.right

theorem subset_inter {s t r : Set α} (rs : r ⊆ s) (rt : r ⊆ t) : r ⊆ s ∩ t := fun _ h =>
  ⟨rs h, rt h⟩

@[simp]
theorem subset_inter_iff {s t r : Set α} : r ⊆ s ∩ t ↔ r ⊆ s ∧ r ⊆ t :=
  (forall_congr' fun _ => imp_and).trans forall_and

@[simp] lemma inter_eq_left : s ∩ t = s ↔ s ⊆ t := inf_eq_left

@[simp] lemma inter_eq_right : s ∩ t = t ↔ t ⊆ s := inf_eq_right

@[simp] lemma left_eq_inter : s = s ∩ t ↔ s ⊆ t := left_eq_inf

@[simp] lemma right_eq_inter : t = s ∩ t ↔ t ⊆ s := right_eq_inf

theorem inter_eq_self_of_subset_left {s t : Set α} : s ⊆ t → s ∩ t = s :=
  inter_eq_left.mpr

theorem inter_eq_self_of_subset_right {s t : Set α} : t ⊆ s → s ∩ t = t :=
  inter_eq_right.mpr

theorem inter_congr_left (ht : s ∩ u ⊆ t) (hu : s ∩ t ⊆ u) : s ∩ t = s ∩ u :=
  inf_congr_left ht hu

theorem inter_congr_right (hs : t ∩ u ⊆ s) (ht : s ∩ u ⊆ t) : s ∩ u = t ∩ u :=
  inf_congr_right hs ht

theorem inter_eq_inter_iff_left : s ∩ t = s ∩ u ↔ s ∩ u ⊆ t ∧ s ∩ t ⊆ u :=
  inf_eq_inf_iff_left

theorem inter_eq_inter_iff_right : s ∩ u = t ∩ u ↔ t ∩ u ⊆ s ∧ s ∩ u ⊆ t :=
  inf_eq_inf_iff_right

@[simp, mfld_simps]
theorem inter_univ (a : Set α) : a ∩ univ = a := inf_top_eq _

@[simp, mfld_simps]
theorem univ_inter (a : Set α) : univ ∩ a = a := top_inf_eq _

@[gcongr]
theorem inter_subset_inter {s₁ s₂ t₁ t₂ : Set α} (h₁ : s₁ ⊆ t₁) (h₂ : s₂ ⊆ t₂) :
    s₁ ∩ s₂ ⊆ t₁ ∩ t₂ := fun _ => And.imp (@h₁ _) (@h₂ _)

@[gcongr]
theorem inter_subset_inter_left {s t : Set α} (u : Set α) (H : s ⊆ t) : s ∩ u ⊆ t ∩ u :=
  inter_subset_inter H Subset.rfl

@[gcongr]
theorem inter_subset_inter_right {s t : Set α} (u : Set α) (H : s ⊆ t) : u ∩ s ⊆ u ∩ t :=
  inter_subset_inter Subset.rfl H

theorem union_inter_cancel_left {s t : Set α} : (s ∪ t) ∩ s = s :=
  inter_eq_self_of_subset_right subset_union_left

theorem union_inter_cancel_right {s t : Set α} : (s ∪ t) ∩ t = t :=
  inter_eq_self_of_subset_right subset_union_right

theorem inter_setOf_eq_sep (s : Set α) (p : α → Prop) : s ∩ {a | p a} = {a ∈ s | p a} :=
  rfl

theorem setOf_inter_eq_sep (p : α → Prop) (s : Set α) : {a | p a} ∩ s = {a ∈ s | p a} :=
  inter_comm _ _

@[simp]
theorem inter_ssubset_right_iff : s ∩ t ⊂ t ↔ ¬ t ⊆ s :=
  inf_lt_right

@[simp]
theorem inter_ssubset_left_iff : s ∩ t ⊂ s ↔ ¬ s ⊆ t :=
  inf_lt_left

/-! ### Distributivity laws -/

theorem inter_union_distrib_left (s t u : Set α) : s ∩ (t ∪ u) = s ∩ t ∪ s ∩ u :=
  inf_sup_left _ _ _

theorem union_inter_distrib_right (s t u : Set α) : (s ∪ t) ∩ u = s ∩ u ∪ t ∩ u :=
  inf_sup_right _ _ _

theorem union_inter_distrib_left (s t u : Set α) : s ∪ t ∩ u = (s ∪ t) ∩ (s ∪ u) :=
  sup_inf_left _ _ _

theorem inter_union_distrib_right (s t u : Set α) : s ∩ t ∪ u = (s ∪ u) ∩ (t ∪ u) :=
  sup_inf_right _ _ _

theorem union_union_distrib_left (s t u : Set α) : s ∪ (t ∪ u) = s ∪ t ∪ (s ∪ u) :=
  sup_sup_distrib_left _ _ _

theorem union_union_distrib_right (s t u : Set α) : s ∪ t ∪ u = s ∪ u ∪ (t ∪ u) :=
  sup_sup_distrib_right _ _ _

theorem inter_inter_distrib_left (s t u : Set α) : s ∩ (t ∩ u) = s ∩ t ∩ (s ∩ u) :=
  inf_inf_distrib_left _ _ _

theorem inter_inter_distrib_right (s t u : Set α) : s ∩ t ∩ u = s ∩ u ∩ (t ∩ u) :=
  inf_inf_distrib_right _ _ _

theorem union_union_union_comm (s t u v : Set α) : s ∪ t ∪ (u ∪ v) = s ∪ u ∪ (t ∪ v) :=
  sup_sup_sup_comm _ _ _ _

theorem inter_inter_inter_comm (s t u v : Set α) : s ∩ t ∩ (u ∩ v) = s ∩ u ∩ (t ∩ v) :=
  inf_inf_inf_comm _ _ _ _

/-! ### Lemmas about sets defined as `{x ∈ s | p x}`. -/

section Sep

variable {p q : α → Prop} {x : α}

theorem mem_sep (xs : x ∈ s) (px : p x) : x ∈ { x ∈ s | p x } :=
  ⟨xs, px⟩

@[simp]
theorem sep_mem_eq : { x ∈ s | x ∈ t } = s ∩ t :=
  rfl

@[simp]
theorem mem_sep_iff : x ∈ { x ∈ s | p x } ↔ x ∈ s ∧ p x :=
  Iff.rfl

theorem sep_ext_iff : { x ∈ s | p x } = { x ∈ s | q x } ↔ ∀ x ∈ s, p x ↔ q x := by
  simp_rw [Set.ext_iff, mem_sep_iff, and_congr_right_iff]

theorem sep_eq_of_subset (h : s ⊆ t) : { x ∈ t | x ∈ s } = s :=
  inter_eq_self_of_subset_right h

@[simp]
theorem sep_subset (s : Set α) (p : α → Prop) : { x ∈ s | p x } ⊆ s := fun _ => And.left

@[simp]
theorem sep_eq_self_iff_mem_true : { x ∈ s | p x } = s ↔ ∀ x ∈ s, p x := by
  simp_rw [Set.ext_iff, mem_sep_iff, and_iff_left_iff_imp]

@[simp]
theorem sep_eq_empty_iff_mem_false : { x ∈ s | p x } = ∅ ↔ ∀ x ∈ s, ¬p x := by
  simp_rw [Set.ext_iff, mem_sep_iff, mem_empty_iff_false, iff_false, not_and]

theorem sep_true : { x ∈ s | True } = s :=
  inter_univ s

theorem sep_false : { x ∈ s | False } = ∅ :=
  inter_empty s

theorem sep_empty (p : α → Prop) : { x ∈ (∅ : Set α) | p x } = ∅ :=
  empty_inter {x | p x}

theorem sep_univ : { x ∈ (univ : Set α) | p x } = { x | p x } :=
  univ_inter {x | p x}

@[simp]
theorem sep_union : { x | (x ∈ s ∨ x ∈ t) ∧ p x } = { x ∈ s | p x } ∪ { x ∈ t | p x } :=
  union_inter_distrib_right { x | x ∈ s } { x | x ∈ t } p

@[simp]
theorem sep_inter : { x | (x ∈ s ∧ x ∈ t) ∧ p x } = { x ∈ s | p x } ∩ { x ∈ t | p x } :=
  inter_inter_distrib_right s t {x | p x}

@[simp]
theorem sep_and : { x ∈ s | p x ∧ q x } = { x ∈ s | p x } ∩ { x ∈ s | q x } :=
  inter_inter_distrib_left s {x | p x} {x | q x}

@[simp]
theorem sep_or : { x ∈ s | p x ∨ q x } = { x ∈ s | p x } ∪ { x ∈ s | q x } :=
  inter_union_distrib_left s p q

@[simp]
theorem sep_setOf : { x ∈ { y | p y } | q x } = { x | p x ∧ q x } :=
  rfl

end Sep

/-- See also `Set.sdiff_inter_right_comm`. -/
lemma inter_diff_assoc (a b c : Set α) : (a ∩ b) \ c = a ∩ (b \ c) := inf_sdiff_assoc ..

/-- See also `Set.inter_diff_assoc`. -/
lemma sdiff_inter_right_comm (s t u : Set α) : s \ t ∩ u = (s ∩ u) \ t := sdiff_inf_right_comm ..

lemma inter_sdiff_left_comm (s t u : Set α) : s ∩ (t \ u) = t ∩ (s \ u) := inf_sdiff_left_comm ..

theorem diff_union_diff_cancel (hts : t ⊆ s) (hut : u ⊆ t) : s \ t ∪ t \ u = s \ u :=
  sdiff_sup_sdiff_cancel hts hut

/-- A version of `diff_union_diff_cancel` with more general hypotheses. -/
theorem diff_union_diff_cancel' (hi : s ∩ u ⊆ t) (hu : t ⊆ s ∪ u) : (s \ t) ∪ (t \ u) = s \ u :=
  sdiff_sup_sdiff_cancel' hi hu

theorem diff_diff_eq_sdiff_union (h : u ⊆ s) : s \ (t \ u) = s \ t ∪ u := sdiff_sdiff_eq_sdiff_sup h

theorem inter_diff_distrib_left (s t u : Set α) : s ∩ (t \ u) = (s ∩ t) \ (s ∩ u) :=
  inf_sdiff_distrib_left _ _ _

theorem inter_diff_distrib_right (s t u : Set α) : (s \ t) ∩ u = (s ∩ u) \ (t ∩ u) :=
  inf_sdiff_distrib_right _ _ _

theorem diff_inter_distrib_right (s t r : Set α) : (t ∩ r) \ s = (t \ s) ∩ (r \ s) :=
  inf_sdiff

/-! ### Lemmas about complement -/

theorem compl_def (s : Set α) : sᶜ = { x | x ∉ s } :=
  rfl

theorem mem_compl {s : Set α} {x : α} (h : x ∉ s) : x ∈ sᶜ :=
  h

theorem compl_setOf {α} (p : α → Prop) : { a | p a }ᶜ = { a | ¬p a } :=
  rfl

theorem notMem_of_mem_compl {s : Set α} {x : α} (h : x ∈ sᶜ) : x ∉ s :=
  h

@[deprecated (since := "2025-05-23")] alias not_mem_of_mem_compl := notMem_of_mem_compl

theorem notMem_compl_iff {x : α} : x ∉ sᶜ ↔ x ∈ s :=
  not_not

@[deprecated (since := "2025-05-23")] alias not_mem_compl_iff := notMem_compl_iff

@[simp]
theorem inter_compl_self (s : Set α) : s ∩ sᶜ = ∅ :=
  inf_compl_eq_bot

@[simp]
theorem compl_inter_self (s : Set α) : sᶜ ∩ s = ∅ :=
  compl_inf_eq_bot

@[simp]
theorem compl_empty : (∅ : Set α)ᶜ = univ :=
  compl_bot

@[simp]
theorem compl_union (s t : Set α) : (s ∪ t)ᶜ = sᶜ ∩ tᶜ :=
  compl_sup

theorem compl_inter (s t : Set α) : (s ∩ t)ᶜ = sᶜ ∪ tᶜ :=
  compl_inf

@[simp]
theorem compl_univ : (univ : Set α)ᶜ = ∅ :=
  compl_top

@[simp]
theorem compl_empty_iff {s : Set α} : sᶜ = ∅ ↔ s = univ :=
  compl_eq_bot

@[simp]
theorem compl_univ_iff {s : Set α} : sᶜ = univ ↔ s = ∅ :=
  compl_eq_top

theorem compl_ne_univ : sᶜ ≠ univ ↔ s.Nonempty :=
  compl_univ_iff.not.trans nonempty_iff_ne_empty.symm

lemma inl_compl_union_inr_compl {α β : Type*} {s : Set α} {t : Set β} :
    Sum.inl '' sᶜ ∪ Sum.inr '' tᶜ = (Sum.inl '' s ∪ Sum.inr '' t)ᶜ := by
  rw [compl_union]
  aesop

theorem nonempty_compl : sᶜ.Nonempty ↔ s ≠ univ :=
  (ne_univ_iff_exists_notMem s).symm

theorem union_eq_compl_compl_inter_compl (s t : Set α) : s ∪ t = (sᶜ ∩ tᶜ)ᶜ :=
  ext fun _ => or_iff_not_and_not

theorem inter_eq_compl_compl_union_compl (s t : Set α) : s ∩ t = (sᶜ ∪ tᶜ)ᶜ :=
  ext fun _ => and_iff_not_or_not

@[simp]
theorem union_compl_self (s : Set α) : s ∪ sᶜ = univ :=
  eq_univ_iff_forall.2 fun _ => em _

@[simp]
theorem compl_union_self (s : Set α) : sᶜ ∪ s = univ := by rw [union_comm, union_compl_self]

theorem compl_subset_comm : sᶜ ⊆ t ↔ tᶜ ⊆ s :=
  @compl_le_iff_compl_le _ s _ _

theorem subset_compl_comm : s ⊆ tᶜ ↔ t ⊆ sᶜ :=
  @le_compl_iff_le_compl _ _ _ t

@[simp]
theorem compl_subset_compl : sᶜ ⊆ tᶜ ↔ t ⊆ s :=
  @compl_le_compl_iff_le (Set α) _ _ _

@[gcongr] theorem compl_subset_compl_of_subset (h : t ⊆ s) : sᶜ ⊆ tᶜ := compl_subset_compl.2 h

theorem subset_union_compl_iff_inter_subset {s t u : Set α} : s ⊆ t ∪ uᶜ ↔ s ∩ u ⊆ t :=
  (@isCompl_compl _ u _).le_sup_right_iff_inf_left_le

theorem compl_subset_iff_union {s t : Set α} : sᶜ ⊆ t ↔ s ∪ t = univ :=
  Iff.symm <| eq_univ_iff_forall.trans <| forall_congr' fun _ => or_iff_not_imp_left

theorem inter_subset (a b c : Set α) : a ∩ b ⊆ c ↔ a ⊆ bᶜ ∪ c :=
  forall_congr' fun _ => and_imp.trans <| imp_congr_right fun _ => imp_iff_not_or

theorem inter_compl_nonempty_iff {s t : Set α} : (s ∩ tᶜ).Nonempty ↔ ¬s ⊆ t :=
  (not_subset.trans <| exists_congr fun x => by simp [mem_compl]).symm

/-! ### Lemmas about set difference -/

theorem notMem_diff_of_mem {s t : Set α} {x : α} (hx : x ∈ t) : x ∉ s \ t := fun h => h.2 hx

@[deprecated (since := "2025-05-23")] alias not_mem_diff_of_mem := notMem_diff_of_mem

theorem mem_of_mem_diff {s t : Set α} {x : α} (h : x ∈ s \ t) : x ∈ s :=
  h.left

theorem notMem_of_mem_diff {s t : Set α} {x : α} (h : x ∈ s \ t) : x ∉ t :=
  h.right

@[deprecated (since := "2025-05-23")] alias not_mem_of_mem_diff := notMem_of_mem_diff

theorem diff_eq_compl_inter {s t : Set α} : s \ t = tᶜ ∩ s := by rw [diff_eq, inter_comm]

theorem diff_nonempty {s t : Set α} : (s \ t).Nonempty ↔ ¬s ⊆ t :=
  inter_compl_nonempty_iff

theorem diff_subset {s t : Set α} : s \ t ⊆ s := show s \ t ≤ s from sdiff_le

theorem diff_subset_compl (s t : Set α) : s \ t ⊆ tᶜ :=
  diff_eq_compl_inter ▸ inter_subset_left

theorem union_diff_cancel' {s t u : Set α} (h₁ : s ⊆ t) (h₂ : t ⊆ u) : t ∪ u \ s = u :=
  sup_sdiff_cancel' h₁ h₂

theorem union_diff_cancel {s t : Set α} (h : s ⊆ t) : s ∪ t \ s = t :=
  sup_sdiff_cancel_right h

theorem union_diff_cancel_left {s t : Set α} (h : s ∩ t ⊆ ∅) : (s ∪ t) \ s = t :=
  Disjoint.sup_sdiff_cancel_left <| disjoint_iff_inf_le.2 h

theorem union_diff_cancel_right {s t : Set α} (h : s ∩ t ⊆ ∅) : (s ∪ t) \ t = s :=
  Disjoint.sup_sdiff_cancel_right <| disjoint_iff_inf_le.2 h

@[simp]
theorem union_diff_left {s t : Set α} : (s ∪ t) \ s = t \ s :=
  sup_sdiff_left_self

@[simp]
theorem union_diff_right {s t : Set α} : (s ∪ t) \ t = s \ t :=
  sup_sdiff_right_self

theorem union_diff_distrib {s t u : Set α} : (s ∪ t) \ u = s \ u ∪ t \ u :=
  sup_sdiff

@[simp]
theorem inter_diff_self (a b : Set α) : a ∩ (b \ a) = ∅ :=
  inf_sdiff_self_right

@[simp]
theorem inter_union_diff (s t : Set α) : s ∩ t ∪ s \ t = s :=
  sup_inf_sdiff s t

@[simp]
theorem diff_union_inter (s t : Set α) : s \ t ∪ s ∩ t = s := by
  rw [union_comm]
  exact sup_inf_sdiff _ _

@[simp]
theorem inter_union_compl (s t : Set α) : s ∩ t ∪ s ∩ tᶜ = s :=
  inter_union_diff _ _

@[gcongr]
theorem diff_subset_diff {s₁ s₂ t₁ t₂ : Set α} : s₁ ⊆ s₂ → t₂ ⊆ t₁ → s₁ \ t₁ ⊆ s₂ \ t₂ :=
  show s₁ ≤ s₂ → t₂ ≤ t₁ → s₁ \ t₁ ≤ s₂ \ t₂ from sdiff_le_sdiff

@[gcongr]
theorem diff_subset_diff_left {s₁ s₂ t : Set α} (h : s₁ ⊆ s₂) : s₁ \ t ⊆ s₂ \ t :=
  sdiff_le_sdiff_right ‹s₁ ≤ s₂›

@[gcongr]
theorem diff_subset_diff_right {s t u : Set α} (h : t ⊆ u) : s \ u ⊆ s \ t :=
  sdiff_le_sdiff_left ‹t ≤ u›

theorem diff_subset_diff_iff_subset {r : Set α} (hs : s ⊆ r) (ht : t ⊆ r) :
    r \ s ⊆ r \ t ↔ t ⊆ s :=
  sdiff_le_sdiff_iff_le hs ht

theorem compl_eq_univ_diff (s : Set α) : sᶜ = univ \ s :=
  top_sdiff.symm

@[simp]
theorem empty_diff (s : Set α) : (∅ \ s : Set α) = ∅ :=
  bot_sdiff

theorem diff_eq_empty {s t : Set α} : s \ t = ∅ ↔ s ⊆ t :=
  sdiff_eq_bot_iff

@[simp]
theorem diff_empty {s : Set α} : s \ ∅ = s :=
  sdiff_bot

@[simp]
theorem diff_univ (s : Set α) : s \ univ = ∅ :=
  diff_eq_empty.2 (subset_univ s)

theorem diff_diff {u : Set α} : (s \ t) \ u = s \ (t ∪ u) :=
  sdiff_sdiff_left

-- the following statement contains parentheses to help the reader
theorem diff_diff_comm {s t u : Set α} : (s \ t) \ u = (s \ u) \ t :=
  sdiff_sdiff_comm

theorem diff_subset_iff {s t u : Set α} : s \ t ⊆ u ↔ s ⊆ t ∪ u :=
  show s \ t ≤ u ↔ s ≤ t ∪ u from sdiff_le_iff

theorem subset_diff_union (s t : Set α) : s ⊆ s \ t ∪ t :=
  show s ≤ s \ t ∪ t from le_sdiff_sup

theorem diff_union_of_subset {s t : Set α} (h : t ⊆ s) : s \ t ∪ t = s :=
  Subset.antisymm (union_subset diff_subset h) (subset_diff_union _ _)

theorem diff_subset_comm {s t u : Set α} : s \ t ⊆ u ↔ s \ u ⊆ t :=
  show s \ t ≤ u ↔ s \ u ≤ t from sdiff_le_comm

theorem diff_inter {s t u : Set α} : s \ (t ∩ u) = s \ t ∪ s \ u :=
  sdiff_inf

theorem diff_inter_diff : s \ t ∩ (s \ u) = s \ (t ∪ u) :=
  sdiff_sup.symm

theorem diff_compl : s \ tᶜ = s ∩ t :=
  sdiff_compl

theorem compl_diff : (t \ s)ᶜ = s ∪ tᶜ :=
  Eq.trans compl_sdiff himp_eq

theorem diff_diff_right {s t u : Set α} : s \ (t \ u) = s \ t ∪ s ∩ u :=
  sdiff_sdiff_right'

theorem inter_diff_right_comm : (s ∩ t) \ u = s \ u ∩ t := by
  rw [diff_eq, diff_eq, inter_right_comm]

theorem diff_inter_right_comm : (s \ u) ∩ t = (s ∩ t) \ u := by
  rw [diff_eq, diff_eq, inter_right_comm]

@[simp]
theorem union_diff_self {s t : Set α} : s ∪ t \ s = s ∪ t :=
  sup_sdiff_self _ _

@[simp]
theorem diff_union_self {s t : Set α} : s \ t ∪ t = s ∪ t :=
  sdiff_sup_self _ _

@[simp]
theorem diff_inter_self {a b : Set α} : b \ a ∩ a = ∅ :=
  inf_sdiff_self_left

@[simp]
theorem diff_inter_self_eq_diff {s t : Set α} : s \ (t ∩ s) = s \ t :=
  sdiff_inf_self_right _ _

@[simp]
theorem diff_self_inter {s t : Set α} : s \ (s ∩ t) = s \ t :=
  sdiff_inf_self_left _ _

theorem diff_self {s : Set α} : s \ s = ∅ :=
  sdiff_self

theorem diff_diff_right_self (s t : Set α) : s \ (s \ t) = s ∩ t :=
  sdiff_sdiff_right_self

theorem diff_diff_cancel_left {s t : Set α} (h : s ⊆ t) : t \ (t \ s) = s :=
  sdiff_sdiff_eq_self h

theorem union_eq_diff_union_diff_union_inter (s t : Set α) : s ∪ t = s \ t ∪ t \ s ∪ s ∩ t :=
  sup_eq_sdiff_sup_sdiff_sup_inf

@[simp] lemma sdiff_sep_self (s : Set α) (p : α → Prop) : s \ {a ∈ s | p a} = {a ∈ s | ¬ p a} :=
  diff_self_inter

/-! ### Powerset -/

theorem mem_powerset {x s : Set α} (h : x ⊆ s) : x ∈ 𝒫 s := @h

theorem subset_of_mem_powerset {x s : Set α} (h : x ∈ 𝒫 s) : x ⊆ s := @h

@[simp]
theorem mem_powerset_iff (x s : Set α) : x ∈ 𝒫 s ↔ x ⊆ s :=
  Iff.rfl

theorem powerset_inter (s t : Set α) : 𝒫(s ∩ t) = 𝒫 s ∩ 𝒫 t :=
  ext fun _ => subset_inter_iff

@[simp]
theorem powerset_mono : 𝒫 s ⊆ 𝒫 t ↔ s ⊆ t :=
  ⟨fun h => @h _ (fun _ h => h), fun h _ hu _ ha => h (hu ha)⟩

theorem monotone_powerset : Monotone (powerset : Set α → Set (Set α)) := fun _ _ => powerset_mono.2

@[simp]
theorem powerset_nonempty : (𝒫 s).Nonempty :=
  ⟨∅, fun _ h => empty_subset s h⟩

@[simp]
theorem powerset_empty : 𝒫(∅ : Set α) = {∅} :=
  ext fun _ => subset_empty_iff

@[simp]
theorem powerset_univ : 𝒫(univ : Set α) = univ :=
  eq_univ_of_forall subset_univ

/-! ### Sets defined as an if-then-else -/

@[deprecated _root_.mem_dite (since := "2025-01-30")]
protected theorem mem_dite (p : Prop) [Decidable p] (s : p → Set α) (t : ¬ p → Set α) (x : α) :
    (x ∈ if h : p then s h else t h) ↔ (∀ h : p, x ∈ s h) ∧ ∀ h : ¬p, x ∈ t h :=
  _root_.mem_dite

theorem mem_dite_univ_right (p : Prop) [Decidable p] (t : p → Set α) (x : α) :
    (x ∈ if h : p then t h else univ) ↔ ∀ h : p, x ∈ t h := by
  simp [mem_dite]

@[simp]
theorem mem_ite_univ_right (p : Prop) [Decidable p] (t : Set α) (x : α) :
    x ∈ ite p t Set.univ ↔ p → x ∈ t :=
  mem_dite_univ_right p (fun _ => t) x

theorem mem_dite_univ_left (p : Prop) [Decidable p] (t : ¬p → Set α) (x : α) :
    (x ∈ if h : p then univ else t h) ↔ ∀ h : ¬p, x ∈ t h := by
  split_ifs <;> simp_all

@[simp]
theorem mem_ite_univ_left (p : Prop) [Decidable p] (t : Set α) (x : α) :
    x ∈ ite p Set.univ t ↔ ¬p → x ∈ t :=
  mem_dite_univ_left p (fun _ => t) x

theorem mem_dite_empty_right (p : Prop) [Decidable p] (t : p → Set α) (x : α) :
    (x ∈ if h : p then t h else ∅) ↔ ∃ h : p, x ∈ t h := by
  simp only [mem_dite, mem_empty_iff_false, imp_false, not_not]
  exact ⟨fun h => ⟨h.2, h.1 h.2⟩, fun ⟨h₁, h₂⟩ => ⟨fun _ => h₂, h₁⟩⟩

@[simp]
theorem mem_ite_empty_right (p : Prop) [Decidable p] (t : Set α) (x : α) :
    x ∈ ite p t ∅ ↔ p ∧ x ∈ t :=
  (mem_dite_empty_right p (fun _ => t) x).trans (by simp)

theorem mem_dite_empty_left (p : Prop) [Decidable p] (t : ¬p → Set α) (x : α) :
    (x ∈ if h : p then ∅ else t h) ↔ ∃ h : ¬p, x ∈ t h := by
  simp only [mem_dite, mem_empty_iff_false, imp_false]
  exact ⟨fun h => ⟨h.1, h.2 h.1⟩, fun ⟨h₁, h₂⟩ => ⟨fun h => h₁ h, fun _ => h₂⟩⟩

@[simp]
theorem mem_ite_empty_left (p : Prop) [Decidable p] (t : Set α) (x : α) :
    x ∈ ite p ∅ t ↔ ¬p ∧ x ∈ t :=
  (mem_dite_empty_left p (fun _ => t) x).trans (by simp)

/-! ### If-then-else for sets -/

/-- `ite` for sets: `Set.ite t s s' ∩ t = s ∩ t`, `Set.ite t s s' ∩ tᶜ = s' ∩ tᶜ`.
Defined as `s ∩ t ∪ s' \ t`. -/
protected def ite (t s s' : Set α) : Set α :=
  s ∩ t ∪ s' \ t

@[simp]
theorem ite_inter_self (t s s' : Set α) : t.ite s s' ∩ t = s ∩ t := by
  rw [Set.ite, union_inter_distrib_right, diff_inter_self, inter_assoc, inter_self, union_empty]

@[simp]
theorem ite_compl (t s s' : Set α) : tᶜ.ite s s' = t.ite s' s := by
  rw [Set.ite, Set.ite, diff_compl, union_comm, diff_eq]

@[simp]
theorem ite_inter_compl_self (t s s' : Set α) : t.ite s s' ∩ tᶜ = s' ∩ tᶜ := by
  rw [← ite_compl, ite_inter_self]

@[simp]
theorem ite_diff_self (t s s' : Set α) : t.ite s s' \ t = s' \ t :=
  ite_inter_compl_self t s s'

@[simp]
theorem ite_same (t s : Set α) : t.ite s s = s :=
  inter_union_diff _ _

@[simp]
theorem ite_left (s t : Set α) : s.ite s t = s ∪ t := by simp [Set.ite]

@[simp]
theorem ite_right (s t : Set α) : s.ite t s = t ∩ s := by simp [Set.ite]

@[simp]
theorem ite_empty (s s' : Set α) : Set.ite ∅ s s' = s' := by simp [Set.ite]

@[simp]
theorem ite_univ (s s' : Set α) : Set.ite univ s s' = s := by simp [Set.ite]

@[simp]
theorem ite_empty_left (t s : Set α) : t.ite ∅ s = s \ t := by simp [Set.ite]

@[simp]
theorem ite_empty_right (t s : Set α) : t.ite s ∅ = s ∩ t := by simp [Set.ite]

theorem ite_mono (t : Set α) {s₁ s₁' s₂ s₂' : Set α} (h : s₁ ⊆ s₂) (h' : s₁' ⊆ s₂') :
    t.ite s₁ s₁' ⊆ t.ite s₂ s₂' :=
  union_subset_union (inter_subset_inter_left _ h) (inter_subset_inter_left _ h')

theorem ite_subset_union (t s s' : Set α) : t.ite s s' ⊆ s ∪ s' :=
  union_subset_union inter_subset_left diff_subset

theorem inter_subset_ite (t s s' : Set α) : s ∩ s' ⊆ t.ite s s' :=
  ite_same t (s ∩ s') ▸ ite_mono _ inter_subset_left inter_subset_right

theorem ite_inter_inter (t s₁ s₂ s₁' s₂' : Set α) :
    t.ite (s₁ ∩ s₂) (s₁' ∩ s₂') = t.ite s₁ s₁' ∩ t.ite s₂ s₂' := by
  ext x
  simp only [Set.ite, Set.mem_inter_iff, Set.mem_diff, Set.mem_union]
  tauto

theorem ite_inter (t s₁ s₂ s : Set α) : t.ite (s₁ ∩ s) (s₂ ∩ s) = t.ite s₁ s₂ ∩ s := by
  rw [ite_inter_inter, ite_same]

theorem ite_inter_of_inter_eq (t : Set α) {s₁ s₂ s : Set α} (h : s₁ ∩ s = s₂ ∩ s) :
    t.ite s₁ s₂ ∩ s = s₁ ∩ s := by rw [← ite_inter, ← h, ite_same]

theorem subset_ite {t s s' u : Set α} : u ⊆ t.ite s s' ↔ u ∩ t ⊆ s ∧ u \ t ⊆ s' := by
  simp only [subset_def, ← forall_and]
  refine forall_congr' fun x => ?_
  by_cases hx : x ∈ t <;> simp [*, Set.ite]

theorem ite_eq_of_subset_left (t : Set α) {s₁ s₂ : Set α} (h : s₁ ⊆ s₂) :
    t.ite s₁ s₂ = s₁ ∪ (s₂ \ t) := by
  ext x
  by_cases hx : x ∈ t <;> simp [*, Set.ite, or_iff_right_of_imp (@h x)]

theorem ite_eq_of_subset_right (t : Set α) {s₁ s₂ : Set α} (h : s₂ ⊆ s₁) :
    t.ite s₁ s₂ = (s₁ ∩ t) ∪ s₂ := by
  ext x
  by_cases hx : x ∈ t <;> simp [*, Set.ite, or_iff_left_of_imp (@h x)]

end Set

open Set

namespace Function

variable {α : Type*} {β : Type*}

theorem Injective.nonempty_apply_iff {f : Set α → Set β} (hf : Injective f) (h2 : f ∅ = ∅)
    {s : Set α} : (f s).Nonempty ↔ s.Nonempty := by
  rw [nonempty_iff_ne_empty, ← h2, nonempty_iff_ne_empty, hf.ne_iff]

end Function

namespace Subsingleton

variable {α : Type*} [Subsingleton α]

theorem eq_univ_of_nonempty {s : Set α} : s.Nonempty → s = univ := fun ⟨x, hx⟩ =>
  eq_univ_of_forall fun y => Subsingleton.elim x y ▸ hx

@[elab_as_elim]
theorem set_cases {p : Set α → Prop} (h0 : p ∅) (h1 : p univ) (s) : p s :=
  (s.eq_empty_or_nonempty.elim fun h => h.symm ▸ h0) fun h => (eq_univ_of_nonempty h).symm ▸ h1

theorem mem_iff_nonempty {α : Type*} [Subsingleton α] {s : Set α} {x : α} : x ∈ s ↔ s.Nonempty :=
  ⟨fun hx => ⟨x, hx⟩, fun ⟨y, hy⟩ => Subsingleton.elim y x ▸ hy⟩

end Subsingleton

/-! ### Decidability instances for sets -/

namespace Set

variable {α : Type u} (s t : Set α) (a b : α)

instance decidableSdiff [Decidable (a ∈ s)] [Decidable (a ∈ t)] : Decidable (a ∈ s \ t) :=
  inferInstanceAs (Decidable (a ∈ s ∧ a ∉ t))

instance decidableInter [Decidable (a ∈ s)] [Decidable (a ∈ t)] : Decidable (a ∈ s ∩ t) :=
  inferInstanceAs (Decidable (a ∈ s ∧ a ∈ t))

instance decidableUnion [Decidable (a ∈ s)] [Decidable (a ∈ t)] : Decidable (a ∈ s ∪ t) :=
  inferInstanceAs (Decidable (a ∈ s ∨ a ∈ t))

instance decidableCompl [Decidable (a ∈ s)] : Decidable (a ∈ sᶜ) :=
  inferInstanceAs (Decidable (a ∉ s))

instance decidableEmptyset : Decidable (a ∈ (∅ : Set α)) := Decidable.isFalse (by simp)

instance decidableUniv : Decidable (a ∈ univ) := Decidable.isTrue (by simp)

instance decidableInsert [Decidable (a = b)] [Decidable (a ∈ s)] : Decidable (a ∈ insert b s) :=
  inferInstanceAs (Decidable (_ ∨ _))

instance decidableSetOf (p : α → Prop) [Decidable (p a)] : Decidable (a ∈ { a | p a }) := by
  assumption

end Set

variable {α : Type*} {s t u : Set α}

namespace Equiv

/-- Given a predicate `p : α → Prop`, produces an equivalence between
  `Set {a : α // p a}` and `{s : Set α // ∀ a ∈ s, p a}`. -/
protected def setSubtypeComm (p : α → Prop) :
    Set {a : α // p a} ≃ {s : Set α // ∀ a ∈ s, p a} where
  toFun s := ⟨{a | ∃ h : p a, s ⟨a, h⟩}, fun _ h ↦ h.1⟩
  invFun s := {a | a.val ∈ s.val}
  left_inv s := by ext a; exact ⟨fun h ↦ h.2, fun h ↦ ⟨a.property, h⟩⟩
  right_inv s := by ext; exact ⟨fun h ↦ h.2, fun h ↦ ⟨s.property _ h, h⟩⟩

@[simp]
protected lemma setSubtypeComm_apply (p : α → Prop) (s : Set {a // p a}) :
    (Equiv.setSubtypeComm p) s = ⟨{a | ∃ h : p a, ⟨a, h⟩ ∈ s}, fun _ h ↦ h.1⟩ :=
  rfl

@[simp]
protected lemma setSubtypeComm_symm_apply (p : α → Prop) (s : {s // ∀ a ∈ s, p a}) :
    (Equiv.setSubtypeComm p).symm s = {a | a.val ∈ s.val} :=
  rfl

end Equiv
