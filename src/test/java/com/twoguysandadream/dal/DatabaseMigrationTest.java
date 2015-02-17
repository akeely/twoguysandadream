package com.twoguysandadream.dal;

import org.junit.BeforeClass;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;

import java.io.IOException;
import java.util.Map;

import static org.springframework.test.util.AssertionErrors.assertEquals;

/**
 * Created by andrew_keely on 2/17/15.
 */
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(classes = {TestDatabaseConfig.class})
public class DatabaseMigrationTest {

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @BeforeClass
    public static void setupDB() throws IOException {

        TestUtil.copyDatabase();
    }

    @Test
    public void testMigration() {

        jdbcTemplate.execute("INSERT INTO test (name, id) VALUES ('name', 'id')");

        Map<String, Object> result = jdbcTemplate.queryForMap("SELECT name, id FROM test");

        assertEquals("Unexpected name returned.", "name", result.get("name"));
        assertEquals("Unexpected id returned.", "id", result.get("id"));

    }
}
