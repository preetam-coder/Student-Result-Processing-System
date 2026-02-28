/* =====================================================
   STEP 2: CREATE TABLES
===================================================== */

/* STUDENTS TABLE */

CREATE TABLE students (
    student_id SERIAL PRIMARY KEY,
    student_name VARCHAR(100) NOT NULL,
    department VARCHAR(100),
    admission_year INT,
    cgpa NUMERIC(4,2) DEFAULT 0
);


/* SEMESTERS TABLE */

CREATE TABLE semesters (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(50) NOT NULL
);


/* COURSES TABLE */

CREATE TABLE courses (
    course_id SERIAL PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL,
    credits INT NOT NULL CHECK (credits > 0)
);


/* GRADES TABLE */

CREATE TABLE grades (
    grade_id SERIAL PRIMARY KEY,
    student_id INT REFERENCES students(student_id) ON DELETE CASCADE,
    course_id INT REFERENCES courses(course_id) ON DELETE CASCADE,
    semester_id INT REFERENCES semesters(semester_id) ON DELETE CASCADE,
    marks INT CHECK (marks BETWEEN 0 AND 100),
    grade_point NUMERIC(3,1),
    UNIQUE(student_id, course_id, semester_id)
);



/* =====================================================
   STEP 3: INSERT SAMPLE DATA
===================================================== */

/* Students */

INSERT INTO students (student_name, department, admission_year) VALUES
('Rahul Angadi', 'ECE', 2022),
('Ananya Rao', 'CSE', 2022),
('Vikram Singh', 'MECH', 2022);


/* Semesters */

INSERT INTO semesters (semester_name) VALUES
('Semester 1'),
('Semester 2');


/* Courses */

INSERT INTO courses (course_name, credits) VALUES
('Mathematics', 4),
('Physics', 3),
('Programming', 4),
('Electronics', 3);



/* =====================================================
   STEP 4: INSERT GRADES
   Grade Point Logic:
   90-100 = 10
   80-89  = 9
   70-79  = 8
   60-69  = 7
   50-59  = 6
   <50    = 0 (Fail)
===================================================== */

INSERT INTO grades (student_id, course_id, semester_id, marks, grade_point) VALUES
(1,1,1,85,9),
(1,2,1,78,8),
(1,3,1,92,10),

(2,1,1,88,9),
(2,2,1,81,9),
(2,3,1,70,8),

(3,1,1,60,7),
(3,2,1,45,0),
(3,3,1,75,8);



/* =====================================================
   STEP 5: GPA CALCULATION QUERY
   GPA = SUM(grade_point × credits) / SUM(credits)
===================================================== */

SELECT 
    s.student_name,
    sem.semester_name,
    ROUND(SUM(g.grade_point * c.credits) / SUM(c.credits), 2) AS GPA
FROM grades g
JOIN students s ON g.student_id = s.student_id
JOIN courses c ON g.course_id = c.course_id
JOIN semesters sem ON g.semester_id = sem.semester_id
GROUP BY s.student_name, sem.semester_name
ORDER BY GPA DESC;



/* =====================================================
   STEP 6: PASS / FAIL STATISTICS
===================================================== */

SELECT 
    s.student_name,
    COUNT(*) FILTER (WHERE g.grade_point > 0) AS passed_subjects,
    COUNT(*) FILTER (WHERE g.grade_point = 0) AS failed_subjects
FROM grades g
JOIN students s ON g.student_id = s.student_id
GROUP BY s.student_name;



/* =====================================================
   STEP 7: RANK LIST USING WINDOW FUNCTION
===================================================== */

SELECT 
    s.student_name,
    ROUND(SUM(g.grade_point * c.credits) / SUM(c.credits), 2) AS GPA,
    RANK() OVER (ORDER BY SUM(g.grade_point * c.credits) / SUM(c.credits) DESC) AS rank_position
FROM grades g
JOIN students s ON g.student_id = s.student_id
JOIN courses c ON g.course_id = c.course_id
GROUP BY s.student_name;



/* =====================================================
   STEP 8: TRIGGER FOR AUTOMATIC CGPA UPDATE
===================================================== */

/* Function */

CREATE OR REPLACE FUNCTION update_cgpa()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE students
    SET cgpa = (
        SELECT ROUND(SUM(g.grade_point * c.credits) / SUM(c.credits), 2)
        FROM grades g
        JOIN courses c ON g.course_id = c.course_id
        WHERE g.student_id = NEW.student_id
    )
    WHERE student_id = NEW.student_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


/* Trigger */

CREATE TRIGGER cgpa_trigger
AFTER INSERT OR UPDATE ON grades
FOR EACH ROW
EXECUTE FUNCTION update_cgpa();



/* =====================================================
   STEP 9: SEMESTER-WISE RESULT SUMMARY
===================================================== */

SELECT 
    sem.semester_name,
    COUNT(DISTINCT g.student_id) AS total_students,
    ROUND(AVG(g.grade_point),2) AS average_grade_point
FROM grades g
JOIN semesters sem ON g.semester_id = sem.semester_id
GROUP BY sem.semester_name;



/* =====================================================
   STEP 10: EXPORT RESULT SUMMARY
===================================================== */

    SELECT 
        s.student_name,
        s.cgpa
    FROM students s
