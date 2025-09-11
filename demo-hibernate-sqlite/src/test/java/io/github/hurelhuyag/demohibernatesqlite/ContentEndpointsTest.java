package io.github.hurelhuyag.demohibernatesqlite;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.*;
import static org.springframework.restdocs.mockmvc.RestDocumentationRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultHandlers.log;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ActiveProfiles("test")
@AutoConfigureMockMvc
@SpringBootTest
@Sql("classpath:/schema.sql")
@Sql(statements = {
        """
        insert into category(id, parent_id, name) values (1, null, 'cat 1');
        """,
        """
        insert into content(id, content, category_id)
        values(5, 'content 1', 2),(6, 'content 2', 3);
        """
})
class ContentEndpointsTest {

    @Autowired
    MockMvc mvc;

    @Test
    void contextLoads() throws Exception {
        mvc.perform(
            get("/contents")
        ).andDo(log())
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isArray())
            .andExpect(jsonPath("$", hasSize(2)))
        ;
    }
}
