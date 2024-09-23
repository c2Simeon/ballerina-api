import ballerina/http;
import ballerina/sql;

service /api on new http:Listener(3000) {

    //Resource function to Delete a programme by programme code and returns the removed Programme.
    resource function delete delete_programme/[string programme_code]() returns Programmes[]|error {
        // Retrieve the programme details before deletion
        stream<Programmes, sql:Error?> programmeStream = db->query(`
        SELECT * 
        FROM Programmes
        WHERE programme_code = ${programme_code}
        `);

        Programmes[] programmeList = [];
        check from Programmes programme in programmeStream
            do {
                programmeList.push(programme);
            };

        // If no results are found, return an error
        if programmeList.length() == 0 {
            return error("Programme not found.");
        }

        // First, delete related entries in the Courses table
        _ = check db->execute(`
        DELETE FROM Courses
        WHERE programme_code = ${programme_code}
    `);

        // Then, delete the programme
        _ = check db->execute(`
        DELETE FROM Programmes
        WHERE programme_code = ${programme_code}
    `);

        // Return the deleted programme details
        return programmeList;
    }

    //Resouce Function to Retrieve all programmes due for review
    resource function get review_due() returns Reviews[]|error {
        stream<Reviews, sql:Error?> reviewsStream = db->query(`
            SELECT *
            FROM Reviews r
            WHERE r.review_due_date <= CURRENT_DATE
        `);

        Reviews[] reviewList = [];
        check from Reviews reviews in reviewsStream
            do {
                reviewList.push(reviews);
            };

        // If no results are found, return an error
        // if reviewList.length() == 0 {
        //     return error("No Programme is Due");
        // }

        return reviewList;
    }

    //Resource funtion to Retrieve a list of all programmes within the Programme Unit(faculty, department)
    resource function get get_programmes_in_unit/[string unit]() returns Programmes[]|error {
        stream<Programmes, sql:Error?> programmeStream = db->query(`
            SELECT *
            FROM Programmes
            WHERE faculty = ${unit} OR department = ${unit}
        `);

        Programmes[] programmesList = [];
        check from Programmes programme in programmeStream
            do {
                programmesList.push(programme);
            };

        return programmesList;
    }

}

// Resource function to retrieve programme details by programme_code
    resource function get ./[string programme_code]() returns json|error {
        stream<Programmes, sql:Error?> programmeStream = db->query(`
            SELECT * 
            FROM Programmes
            WHERE programme_code = ?`, programme_code);

        Programmes[] programmeList = [];
        
        // Collecting programmes from the stream
        check from Programmes programme in programmeStream
            do {
                programmeList.push(programme);
            };

        // Check if any programmes were found
        if programmeList.length() > 0 {
            // Return the list of programmes as JSON
            return programmeList;
        } else {
            // Return an error if no programme was found
            return { "message": "No programme found with code: " + programme_code };
        }
}

    // Resource function to update an existing programme's information by programme code
    resource function put update_programme/[string programme_code](Programmes programme) returns Programmes[]|error {

        boolean updated = false;

        if programme.programme_name is string {
            _ = check db->execute(`UPDATE Programmes SET programme_name = ${programme.programme_name} WHERE programme_code = ${programme_code}`);
            updated = true;
        }
        if programme.NQF_level is string {
            _ = check db->execute(`UPDATE Programmes SET NQF_level = ${programme.NQF_level} WHERE programme_code = ${programme_code}`);
            updated = true;
        }
        if programme.faculty is string {
            _ = check db->execute(`UPDATE Programmes SET faculty = ${programme.faculty} WHERE programme_code = ${programme_code}`);
            updated = true;
        }
        if programme.department is string {
            _ = check db->execute(`UPDATE Programmes SET department = ${programme.department} WHERE programme_code = ${programme_code}`);
            updated = true;
        }

        if !updated {
            return error("No fields provided for update");
        }

        stream<Programmes, sql:Error?> programmeStream = db->query(`SELECT * FROM Programmes WHERE programme_code = ${programme_code}`);

        // Collect results from the stream into a list
        Programmes[] programmeList = [];
        check from Programmes programmes in programmeStream
            do {
                programmeList.push(programmes);
            };

        return programmeList;
    }
