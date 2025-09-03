# proyecto_movil

Students will develop a mobile application using **Flutter** that allows students to evaluate the performance and commitment of their peers in collaborative course activities.

## Functional Requirements

### Courses and Roles
- Any authenticated user can create up to **3 courses**.
- The creator of a course becomes its **teacher**.
- A teacher can **invite users** to join a course.  
  - Invitations must be **private** or include a **verification method**.
- Invited users become **students** in that course.
- A user can be a **student in multiple courses**.

### Group Categories
- Teachers can create **categories** to organize students into groups.
- Each category has a **name** and a **grouping method**:
  - **Random**: groups are formed automatically with **X students** in each.
  - **Self-assigned**: students choose their groups, up to **X members**.
- Teachers can also:
  - **Manually create or edit groups**.
  - **Move students** between groups.

### Activities and Assessment
- Teachers can create **activities**; each tied to **one category**.
- A category can have **multiple activities**.
- For each activity, teachers can **launch one assessment**.

## Assessment Parameters
An assessment gives each member of a group the opportunity to evaluate the work and attitude of their peers; **there is no self-evaluation**. Each assessment includes:

- **Name**
- **Time window** (duration of availability in minutes or hours)
- **Visibility**:
  - **Public**: results are shown to the group members (criteria scores + general score).
  - **Private**: results are visible only to the teacher.

## Scoring Access
Teachers can view:
- **Activity average** (all groups)
- **Group average** (across activities)
- **Student average** (across activities)
- **Detailed results** per **group → student → criteria score**

---

## First Release (Implemented)
- **User authentication** functionality done by student Justine Barreto.
- **Add courses** and **view enrolled users** done by student Justine Barreto.
- **CRUD for categories** done by Andrés Evertsz.
- **View courses** a user is enrolled in done by Andrés Evertsz.
- **Integrated Home screen**.

- All functionality can be implemented using **in-memory structures (lists)**, without the need for database persistence.









