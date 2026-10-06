package io.github.hurelhuyag.demohibernatesqlite;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.jdbc.Sql;
import org.springframework.test.web.servlet.MockMvc;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;

import static org.springframework.test.context.jdbc.Sql.ExecutionPhase.AFTER_TEST_METHOD;
import static org.springframework.test.json.JsonCompareMode.STRICT;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/// The same 16 cases exist in every demo-*/ project. They run against a copy of the repo's
/// demo.sqlite (built by db/generate.sql): 100 categories in 3 levels, 100,000 contents.
/// STRICT compares the whole document: values, array order, and no missing or extra fields.
@ActiveProfiles("test")
@AutoConfigureMockMvc
@SpringBootTest
class ContentEndpointsTest {

    static final String RESTORE_CONTENT_2 = "update content set content = 'Analysis: NBA #2' where id = 2";

    @DynamicPropertySource
    static void copyOfDemoDatabase(DynamicPropertyRegistry registry) throws IOException {
        var copy = Files.createTempFile("demo", ".sqlite");
        Files.copy(Path.of("../demo.sqlite"), copy, StandardCopyOption.REPLACE_EXISTING);
        copy.toFile().deleteOnExit();
        registry.add("spring.datasource.url", () -> "jdbc:sqlite:" + copy);
    }

    @Autowired
    MockMvc mvc;

    // The list is ordered by id DESC, unlike the other demos.
    @Test
    void listDefault() throws Exception {
        mvc.perform(get("/contents"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {
                  "content": [
                    {"id": 100000, "content": "Uncategorized note 100000", "category": null},
                    {"id": 99999, "content": "Explainer: Large Language Models #99999",
                     "category": {"id": 211, "name": "Large Language Models", "parent":
                       {"id": 21, "name": "Artificial Intelligence", "parent":
                         {"id": 2, "name": "Technology", "parent": null}}}},
                    {"id": 99998, "content": "Opinion: Street Style #99998",
                     "category": {"id": 1021, "name": "Street Style", "parent":
                       {"id": 102, "name": "Fashion", "parent":
                         {"id": 10, "name": "Lifestyle", "parent": null}}}},
                    {"id": 99997, "content": "Analysis: Animation #99997",
                     "category": {"id": 513, "name": "Animation", "parent":
                       {"id": 51, "name": "Movies", "parent":
                         {"id": 5, "name": "Entertainment", "parent": null}}}},
                    {"id": 99996, "content": "Latest report: Entertainment #99996",
                     "category": {"id": 5, "name": "Entertainment", "parent": null}},
                    {"id": 99995, "content": "Breaking news: Acquisitions #99995",
                     "category": {"id": 422, "name": "Acquisitions", "parent":
                       {"id": 42, "name": "Startups", "parent":
                         {"id": 4, "name": "Business", "parent": null}}}},
                    {"id": 99994, "content": "Live updates: Television #99994",
                     "category": {"id": 53, "name": "Television", "parent":
                       {"id": 5, "name": "Entertainment", "parent": null}}},
                    {"id": 99993, "content": "Interview: Grand Slams #99993",
                     "category": {"id": 331, "name": "Grand Slams", "parent":
                       {"id": 33, "name": "Tennis", "parent":
                         {"id": 3, "name": "Sports", "parent": null}}}},
                    {"id": 99992, "content": "Explainer: Food & Drink #99992",
                     "category": {"id": 101, "name": "Food & Drink", "parent":
                       {"id": 10, "name": "Lifestyle", "parent": null}}},
                    {"id": 99991, "content": "Opinion: Admissions #99991",
                     "category": {"id": 911, "name": "Admissions", "parent":
                       {"id": 91, "name": "Universities", "parent":
                         {"id": 9, "name": "Education", "parent": null}}}},
                    {"id": 99990, "content": "Analysis: Lifestyle #99990",
                     "category": {"id": 10, "name": "Lifestyle", "parent": null}},
                    {"id": 99989, "content": "Latest report: Champions League #99989",
                     "category": {"id": 312, "name": "Champions League", "parent":
                       {"id": 31, "name": "Football", "parent":
                         {"id": 3, "name": "Sports", "parent": null}}}},
                    {"id": 99988, "content": "Breaking news: Airlines #99988",
                     "category": {"id": 82, "name": "Airlines", "parent":
                       {"id": 8, "name": "Travel", "parent": null}}},
                    {"id": 99987, "content": "Live updates: Chips #99987",
                     "category": {"id": 221, "name": "Chips", "parent":
                       {"id": 22, "name": "Hardware", "parent":
                         {"id": 2, "name": "Technology", "parent": null}}}},
                    {"id": 99986, "content": "Interview: Interior Design #99986",
                     "category": {"id": 1031, "name": "Interior Design", "parent":
                       {"id": 103, "name": "Home & Garden", "parent":
                         {"id": 10, "name": "Lifestyle", "parent": null}}}},
                    {"id": 99985, "content": "Explainer: Employment #99985",
                     "category": {"id": 432, "name": "Employment", "parent":
                       {"id": 43, "name": "Economy", "parent":
                         {"id": 4, "name": "Business", "parent": null}}}},
                    {"id": 99984, "content": "Opinion: Biology #99984",
                     "category": {"id": 63, "name": "Biology", "parent":
                       {"id": 6, "name": "Science", "parent": null}}},
                    {"id": 99983, "content": "Analysis: Restaurants #99983",
                     "category": {"id": 1012, "name": "Restaurants", "parent":
                       {"id": 101, "name": "Food & Drink", "parent":
                         {"id": 10, "name": "Lifestyle", "parent": null}}}},
                    {"id": 99982, "content": "Latest report: US Elections #99982",
                     "category": {"id": 111, "name": "US Elections", "parent":
                       {"id": 11, "name": "Elections", "parent":
                         {"id": 1, "name": "Politics", "parent": null}}}},
                    {"id": 99981, "content": "Breaking news: Curriculum #99981",
                     "category": {"id": 921, "name": "Curriculum", "parent":
                       {"id": 92, "name": "Schools", "parent":
                         {"id": 9, "name": "Education", "parent": null}}}}
                  ],
                  "empty": false,
                  "first": true,
                  "last": false,
                  "number": 0,
                  "numberOfElements": 20,
                  "size": 20,
                  "sort": {"empty": true, "sorted": false, "unsorted": true},
                  "pageable": {
                    "offset": 0,
                    "pageNumber": 0,
                    "pageSize": 20,
                    "paged": true,
                    "unpaged": false,
                    "sort": {"empty": true, "sorted": false, "unsorted": true}
                  }
                }
                """, STRICT));
    }

    // Spring pages are 0-based, so page=1 is the second page.
    @Test
    void listPage2Size2() throws Exception {
        mvc.perform(get("/contents?page=1&size=2"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {
                  "content": [
                    {"id": 99998, "content": "Opinion: Street Style #99998",
                     "category": {"id": 1021, "name": "Street Style", "parent":
                       {"id": 102, "name": "Fashion", "parent":
                         {"id": 10, "name": "Lifestyle", "parent": null}}}},
                    {"id": 99997, "content": "Analysis: Animation #99997",
                     "category": {"id": 513, "name": "Animation", "parent":
                       {"id": 51, "name": "Movies", "parent":
                         {"id": 5, "name": "Entertainment", "parent": null}}}}
                  ],
                  "empty": false,
                  "first": false,
                  "last": false,
                  "number": 1,
                  "numberOfElements": 2,
                  "size": 2,
                  "sort": {"empty": true, "sorted": false, "unsorted": true},
                  "pageable": {
                    "offset": 2,
                    "pageNumber": 1,
                    "pageSize": 2,
                    "paged": true,
                    "unpaged": false,
                    "sort": {"empty": true, "sorted": false, "unsorted": true}
                  }
                }
                """, STRICT));
    }

    @Test
    void listPastTheEnd() throws Exception {
        mvc.perform(get("/contents?page=10000"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {
                  "content": [],
                  "empty": true,
                  "first": false,
                  "last": true,
                  "number": 10000,
                  "numberOfElements": 0,
                  "size": 20,
                  "sort": {"empty": true, "sorted": false, "unsorted": true},
                  "pageable": {
                    "offset": 200000,
                    "pageNumber": 10000,
                    "pageSize": 20,
                    "paged": true,
                    "unpaged": false,
                    "sort": {"empty": true, "sorted": false, "unsorted": true}
                  }
                }
                """, STRICT));
    }

    // Spring Data does not reject a size below 1; it falls back to the default of 20.
    @Test
    void listSizeZero() throws Exception {
        mvc.perform(get("/contents?size=0"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {
                  "content": [
                    {"id": 100000, "content": "Uncategorized note 100000", "category": null},
                    {"id": 99999, "content": "Explainer: Large Language Models #99999",
                     "category": {"id": 211, "name": "Large Language Models", "parent":
                       {"id": 21, "name": "Artificial Intelligence", "parent":
                         {"id": 2, "name": "Technology", "parent": null}}}},
                    {"id": 99998, "content": "Opinion: Street Style #99998",
                     "category": {"id": 1021, "name": "Street Style", "parent":
                       {"id": 102, "name": "Fashion", "parent":
                         {"id": 10, "name": "Lifestyle", "parent": null}}}},
                    {"id": 99997, "content": "Analysis: Animation #99997",
                     "category": {"id": 513, "name": "Animation", "parent":
                       {"id": 51, "name": "Movies", "parent":
                         {"id": 5, "name": "Entertainment", "parent": null}}}},
                    {"id": 99996, "content": "Latest report: Entertainment #99996",
                     "category": {"id": 5, "name": "Entertainment", "parent": null}},
                    {"id": 99995, "content": "Breaking news: Acquisitions #99995",
                     "category": {"id": 422, "name": "Acquisitions", "parent":
                       {"id": 42, "name": "Startups", "parent":
                         {"id": 4, "name": "Business", "parent": null}}}},
                    {"id": 99994, "content": "Live updates: Television #99994",
                     "category": {"id": 53, "name": "Television", "parent":
                       {"id": 5, "name": "Entertainment", "parent": null}}},
                    {"id": 99993, "content": "Interview: Grand Slams #99993",
                     "category": {"id": 331, "name": "Grand Slams", "parent":
                       {"id": 33, "name": "Tennis", "parent":
                         {"id": 3, "name": "Sports", "parent": null}}}},
                    {"id": 99992, "content": "Explainer: Food & Drink #99992",
                     "category": {"id": 101, "name": "Food & Drink", "parent":
                       {"id": 10, "name": "Lifestyle", "parent": null}}},
                    {"id": 99991, "content": "Opinion: Admissions #99991",
                     "category": {"id": 911, "name": "Admissions", "parent":
                       {"id": 91, "name": "Universities", "parent":
                         {"id": 9, "name": "Education", "parent": null}}}},
                    {"id": 99990, "content": "Analysis: Lifestyle #99990",
                     "category": {"id": 10, "name": "Lifestyle", "parent": null}},
                    {"id": 99989, "content": "Latest report: Champions League #99989",
                     "category": {"id": 312, "name": "Champions League", "parent":
                       {"id": 31, "name": "Football", "parent":
                         {"id": 3, "name": "Sports", "parent": null}}}},
                    {"id": 99988, "content": "Breaking news: Airlines #99988",
                     "category": {"id": 82, "name": "Airlines", "parent":
                       {"id": 8, "name": "Travel", "parent": null}}},
                    {"id": 99987, "content": "Live updates: Chips #99987",
                     "category": {"id": 221, "name": "Chips", "parent":
                       {"id": 22, "name": "Hardware", "parent":
                         {"id": 2, "name": "Technology", "parent": null}}}},
                    {"id": 99986, "content": "Interview: Interior Design #99986",
                     "category": {"id": 1031, "name": "Interior Design", "parent":
                       {"id": 103, "name": "Home & Garden", "parent":
                         {"id": 10, "name": "Lifestyle", "parent": null}}}},
                    {"id": 99985, "content": "Explainer: Employment #99985",
                     "category": {"id": 432, "name": "Employment", "parent":
                       {"id": 43, "name": "Economy", "parent":
                         {"id": 4, "name": "Business", "parent": null}}}},
                    {"id": 99984, "content": "Opinion: Biology #99984",
                     "category": {"id": 63, "name": "Biology", "parent":
                       {"id": 6, "name": "Science", "parent": null}}},
                    {"id": 99983, "content": "Analysis: Restaurants #99983",
                     "category": {"id": 1012, "name": "Restaurants", "parent":
                       {"id": 101, "name": "Food & Drink", "parent":
                         {"id": 10, "name": "Lifestyle", "parent": null}}}},
                    {"id": 99982, "content": "Latest report: US Elections #99982",
                     "category": {"id": 111, "name": "US Elections", "parent":
                       {"id": 11, "name": "Elections", "parent":
                         {"id": 1, "name": "Politics", "parent": null}}}},
                    {"id": 99981, "content": "Breaking news: Curriculum #99981",
                     "category": {"id": 921, "name": "Curriculum", "parent":
                       {"id": 92, "name": "Schools", "parent":
                         {"id": 9, "name": "Education", "parent": null}}}}
                  ],
                  "empty": false,
                  "first": true,
                  "last": false,
                  "number": 0,
                  "numberOfElements": 20,
                  "size": 20,
                  "sort": {"empty": true, "sorted": false, "unsorted": true},
                  "pageable": {
                    "offset": 0,
                    "pageNumber": 0,
                    "pageSize": 20,
                    "paged": true,
                    "unpaged": false,
                    "sort": {"empty": true, "sorted": false, "unsorted": true}
                  }
                }
                """, STRICT));
    }

    @Test
    void itemInRootCategory() throws Exception {
        mvc.perform(get("/contents/12"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {"id": 12, "content": "Interview: Education #12",
                  "category": {"id": 9, "name": "Education", "parent": null}}
                """, STRICT));
    }

    @Test
    void itemInLevel2Category() throws Exception {
        mvc.perform(get("/contents/1"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {"id": 1, "content": "Latest report: Universities #1",
                  "category": {"id": 91, "name": "Universities", "parent":
                    {"id": 9, "name": "Education", "parent": null}}}
                """, STRICT));
    }

    @Test
    void itemInLevel3Category() throws Exception {
        mvc.perform(get("/contents/2"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {"id": 2, "content": "Analysis: NBA #2",
                  "category": {"id": 321, "name": "NBA", "parent":
                    {"id": 32, "name": "Basketball", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}}}
                """, STRICT));
    }

    @Test
    void itemWithoutCategory() throws Exception {
        mvc.perform(get("/contents/1000"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {"id": 1000, "content": "Uncategorized note 1000", "category": null}
                """, STRICT));
    }

    @Test
    void itemNotFound() throws Exception {
        mvc.perform(get("/contents/100001"))
            .andExpect(status().isNotFound())
            .andExpect(content().json("""
                {
                  "title": "Not Found",
                  "status": 404,
                  "detail": "Content 100001 not found",
                  "instance": "/contents/100001"
                }
                """, STRICT));
    }

    @Test
    void itemNonNumericId() throws Exception {
        mvc.perform(get("/contents/abc"))
            .andExpect(status().isBadRequest())
            .andExpect(content().json("""
                {
                  "title": "Bad Request",
                  "status": 400,
                  "detail": "Failed to convert 'id' with value: 'abc'",
                  "instance": "/contents/abc"
                }
                """, STRICT));
    }

    @Test
    @Sql(statements = RESTORE_CONTENT_2, executionPhase = AFTER_TEST_METHOD)
    void updateContent() throws Exception {
        mvc.perform(put("/contents/2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content": "updated text"}
                    """))
            .andExpect(status().isOk())
            // The update does not load the category, so the response has "category": null.
            .andExpect(content().json("""
                {"id": 2, "content": "updated text", "category": null}
                """, STRICT));

        mvc.perform(get("/contents/2"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                {"id": 2, "content": "updated text",
                  "category": {"id": 321, "name": "NBA", "parent":
                    {"id": 32, "name": "Basketball", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}}}
                """, STRICT));
    }

    @Test
    void updateEmptyContent() throws Exception {
        mvc.perform(put("/contents/2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content": ""}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(content().json("""
                {
                  "title": "Bad Request",
                  "status": 400,
                  "detail": "Invalid request content.",
                  "instance": "/contents/2",
                  "errors": [{"field": "content", "message": "must not be blank"}]
                }
                """, STRICT));
    }

    @Test
    void updateMissingContentField() throws Exception {
        mvc.perform(put("/contents/2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(content().json("""
                {
                  "title": "Bad Request",
                  "status": 400,
                  "detail": "Invalid request content.",
                  "instance": "/contents/2",
                  "errors": [{"field": "content", "message": "must not be blank"}]
                }
                """, STRICT));
    }

    @Test
    void updateMalformedJson() throws Exception {
        mvc.perform(put("/contents/2")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(content().json("""
                {
                  "title": "Bad Request",
                  "status": 400,
                  "detail": "Failed to read request",
                  "instance": "/contents/2"
                }
                """, STRICT));
    }

    @Test
    void updateNotFound() throws Exception {
        mvc.perform(put("/contents/100001")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"content": "x"}
                    """))
            .andExpect(status().isNotFound())
            .andExpect(content().json("""
                {
                  "title": "Not Found",
                  "status": 404,
                  "detail": "Content 100001 not found",
                  "instance": "/contents/100001"
                }
                """, STRICT));
    }

    @Test
    void categories() throws Exception {
        mvc.perform(get("/categories"))
            .andExpect(status().isOk())
            .andExpect(content().json("""
                [
                  {"id": 1, "name": "Politics", "parent": null},
                  {"id": 2, "name": "Technology", "parent": null},
                  {"id": 3, "name": "Sports", "parent": null},
                  {"id": 4, "name": "Business", "parent": null},
                  {"id": 5, "name": "Entertainment", "parent": null},
                  {"id": 6, "name": "Science", "parent": null},
                  {"id": 7, "name": "Health", "parent": null},
                  {"id": 8, "name": "Travel", "parent": null},
                  {"id": 9, "name": "Education", "parent": null},
                  {"id": 10, "name": "Lifestyle", "parent": null},
                  {"id": 11, "name": "Elections", "parent":
                    {"id": 1, "name": "Politics", "parent": null}},
                  {"id": 12, "name": "Policy", "parent":
                    {"id": 1, "name": "Politics", "parent": null}},
                  {"id": 13, "name": "Diplomacy", "parent":
                    {"id": 1, "name": "Politics", "parent": null}},
                  {"id": 21, "name": "Artificial Intelligence", "parent":
                    {"id": 2, "name": "Technology", "parent": null}},
                  {"id": 22, "name": "Hardware", "parent":
                    {"id": 2, "name": "Technology", "parent": null}},
                  {"id": 23, "name": "Software", "parent":
                    {"id": 2, "name": "Technology", "parent": null}},
                  {"id": 31, "name": "Football", "parent":
                    {"id": 3, "name": "Sports", "parent": null}},
                  {"id": 32, "name": "Basketball", "parent":
                    {"id": 3, "name": "Sports", "parent": null}},
                  {"id": 33, "name": "Tennis", "parent":
                    {"id": 3, "name": "Sports", "parent": null}},
                  {"id": 41, "name": "Markets", "parent":
                    {"id": 4, "name": "Business", "parent": null}},
                  {"id": 42, "name": "Startups", "parent":
                    {"id": 4, "name": "Business", "parent": null}},
                  {"id": 43, "name": "Economy", "parent":
                    {"id": 4, "name": "Business", "parent": null}},
                  {"id": 51, "name": "Movies", "parent":
                    {"id": 5, "name": "Entertainment", "parent": null}},
                  {"id": 52, "name": "Music", "parent":
                    {"id": 5, "name": "Entertainment", "parent": null}},
                  {"id": 53, "name": "Television", "parent":
                    {"id": 5, "name": "Entertainment", "parent": null}},
                  {"id": 61, "name": "Space", "parent":
                    {"id": 6, "name": "Science", "parent": null}},
                  {"id": 62, "name": "Climate", "parent":
                    {"id": 6, "name": "Science", "parent": null}},
                  {"id": 63, "name": "Biology", "parent":
                    {"id": 6, "name": "Science", "parent": null}},
                  {"id": 71, "name": "Fitness", "parent":
                    {"id": 7, "name": "Health", "parent": null}},
                  {"id": 72, "name": "Nutrition", "parent":
                    {"id": 7, "name": "Health", "parent": null}},
                  {"id": 73, "name": "Medicine", "parent":
                    {"id": 7, "name": "Health", "parent": null}},
                  {"id": 81, "name": "Destinations", "parent":
                    {"id": 8, "name": "Travel", "parent": null}},
                  {"id": 82, "name": "Airlines", "parent":
                    {"id": 8, "name": "Travel", "parent": null}},
                  {"id": 83, "name": "Hotels", "parent":
                    {"id": 8, "name": "Travel", "parent": null}},
                  {"id": 91, "name": "Universities", "parent":
                    {"id": 9, "name": "Education", "parent": null}},
                  {"id": 92, "name": "Schools", "parent":
                    {"id": 9, "name": "Education", "parent": null}},
                  {"id": 93, "name": "Online Learning", "parent":
                    {"id": 9, "name": "Education", "parent": null}},
                  {"id": 101, "name": "Food & Drink", "parent":
                    {"id": 10, "name": "Lifestyle", "parent": null}},
                  {"id": 102, "name": "Fashion", "parent":
                    {"id": 10, "name": "Lifestyle", "parent": null}},
                  {"id": 103, "name": "Home & Garden", "parent":
                    {"id": 10, "name": "Lifestyle", "parent": null}},
                  {"id": 111, "name": "US Elections", "parent":
                    {"id": 11, "name": "Elections", "parent":
                      {"id": 1, "name": "Politics", "parent": null}}},
                  {"id": 112, "name": "EU Elections", "parent":
                    {"id": 11, "name": "Elections", "parent":
                      {"id": 1, "name": "Politics", "parent": null}}},
                  {"id": 113, "name": "Local Elections", "parent":
                    {"id": 11, "name": "Elections", "parent":
                      {"id": 1, "name": "Politics", "parent": null}}},
                  {"id": 121, "name": "Healthcare Policy", "parent":
                    {"id": 12, "name": "Policy", "parent":
                      {"id": 1, "name": "Politics", "parent": null}}},
                  {"id": 122, "name": "Tax Policy", "parent":
                    {"id": 12, "name": "Policy", "parent":
                      {"id": 1, "name": "Politics", "parent": null}}},
                  {"id": 131, "name": "Trade Agreements", "parent":
                    {"id": 13, "name": "Diplomacy", "parent":
                      {"id": 1, "name": "Politics", "parent": null}}},
                  {"id": 211, "name": "Large Language Models", "parent":
                    {"id": 21, "name": "Artificial Intelligence", "parent":
                      {"id": 2, "name": "Technology", "parent": null}}},
                  {"id": 212, "name": "Computer Vision", "parent":
                    {"id": 21, "name": "Artificial Intelligence", "parent":
                      {"id": 2, "name": "Technology", "parent": null}}},
                  {"id": 213, "name": "Robotics", "parent":
                    {"id": 21, "name": "Artificial Intelligence", "parent":
                      {"id": 2, "name": "Technology", "parent": null}}},
                  {"id": 221, "name": "Chips", "parent":
                    {"id": 22, "name": "Hardware", "parent":
                      {"id": 2, "name": "Technology", "parent": null}}},
                  {"id": 222, "name": "Smartphones", "parent":
                    {"id": 22, "name": "Hardware", "parent":
                      {"id": 2, "name": "Technology", "parent": null}}},
                  {"id": 231, "name": "Open Source", "parent":
                    {"id": 23, "name": "Software", "parent":
                      {"id": 2, "name": "Technology", "parent": null}}},
                  {"id": 232, "name": "Cloud Computing", "parent":
                    {"id": 23, "name": "Software", "parent":
                      {"id": 2, "name": "Technology", "parent": null}}},
                  {"id": 311, "name": "Premier League", "parent":
                    {"id": 31, "name": "Football", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}},
                  {"id": 312, "name": "Champions League", "parent":
                    {"id": 31, "name": "Football", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}},
                  {"id": 313, "name": "La Liga", "parent":
                    {"id": 31, "name": "Football", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}},
                  {"id": 321, "name": "NBA", "parent":
                    {"id": 32, "name": "Basketball", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}},
                  {"id": 322, "name": "EuroLeague", "parent":
                    {"id": 32, "name": "Basketball", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}},
                  {"id": 331, "name": "Grand Slams", "parent":
                    {"id": 33, "name": "Tennis", "parent":
                      {"id": 3, "name": "Sports", "parent": null}}},
                  {"id": 411, "name": "Stocks", "parent":
                    {"id": 41, "name": "Markets", "parent":
                      {"id": 4, "name": "Business", "parent": null}}},
                  {"id": 412, "name": "Commodities", "parent":
                    {"id": 41, "name": "Markets", "parent":
                      {"id": 4, "name": "Business", "parent": null}}},
                  {"id": 413, "name": "Crypto", "parent":
                    {"id": 41, "name": "Markets", "parent":
                      {"id": 4, "name": "Business", "parent": null}}},
                  {"id": 421, "name": "Funding", "parent":
                    {"id": 42, "name": "Startups", "parent":
                      {"id": 4, "name": "Business", "parent": null}}},
                  {"id": 422, "name": "Acquisitions", "parent":
                    {"id": 42, "name": "Startups", "parent":
                      {"id": 4, "name": "Business", "parent": null}}},
                  {"id": 431, "name": "Inflation", "parent":
                    {"id": 43, "name": "Economy", "parent":
                      {"id": 4, "name": "Business", "parent": null}}},
                  {"id": 432, "name": "Employment", "parent":
                    {"id": 43, "name": "Economy", "parent":
                      {"id": 4, "name": "Business", "parent": null}}},
                  {"id": 511, "name": "Box Office", "parent":
                    {"id": 51, "name": "Movies", "parent":
                      {"id": 5, "name": "Entertainment", "parent": null}}},
                  {"id": 512, "name": "Film Festivals", "parent":
                    {"id": 51, "name": "Movies", "parent":
                      {"id": 5, "name": "Entertainment", "parent": null}}},
                  {"id": 513, "name": "Animation", "parent":
                    {"id": 51, "name": "Movies", "parent":
                      {"id": 5, "name": "Entertainment", "parent": null}}},
                  {"id": 521, "name": "Concerts", "parent":
                    {"id": 52, "name": "Music", "parent":
                      {"id": 5, "name": "Entertainment", "parent": null}}},
                  {"id": 522, "name": "Albums", "parent":
                    {"id": 52, "name": "Music", "parent":
                      {"id": 5, "name": "Entertainment", "parent": null}}},
                  {"id": 611, "name": "Mars Missions", "parent":
                    {"id": 61, "name": "Space", "parent":
                      {"id": 6, "name": "Science", "parent": null}}},
                  {"id": 612, "name": "Telescopes", "parent":
                    {"id": 61, "name": "Space", "parent":
                      {"id": 6, "name": "Science", "parent": null}}},
                  {"id": 621, "name": "Extreme Weather", "parent":
                    {"id": 62, "name": "Climate", "parent":
                      {"id": 6, "name": "Science", "parent": null}}},
                  {"id": 622, "name": "Renewable Energy", "parent":
                    {"id": 62, "name": "Climate", "parent":
                      {"id": 6, "name": "Science", "parent": null}}},
                  {"id": 631, "name": "Genetics", "parent":
                    {"id": 63, "name": "Biology", "parent":
                      {"id": 6, "name": "Science", "parent": null}}},
                  {"id": 632, "name": "Neuroscience", "parent":
                    {"id": 63, "name": "Biology", "parent":
                      {"id": 6, "name": "Science", "parent": null}}},
                  {"id": 711, "name": "Running", "parent":
                    {"id": 71, "name": "Fitness", "parent":
                      {"id": 7, "name": "Health", "parent": null}}},
                  {"id": 712, "name": "Strength Training", "parent":
                    {"id": 71, "name": "Fitness", "parent":
                      {"id": 7, "name": "Health", "parent": null}}},
                  {"id": 721, "name": "Diets", "parent":
                    {"id": 72, "name": "Nutrition", "parent":
                      {"id": 7, "name": "Health", "parent": null}}},
                  {"id": 722, "name": "Supplements", "parent":
                    {"id": 72, "name": "Nutrition", "parent":
                      {"id": 7, "name": "Health", "parent": null}}},
                  {"id": 731, "name": "Vaccines", "parent":
                    {"id": 73, "name": "Medicine", "parent":
                      {"id": 7, "name": "Health", "parent": null}}},
                  {"id": 732, "name": "Mental Health", "parent":
                    {"id": 73, "name": "Medicine", "parent":
                      {"id": 7, "name": "Health", "parent": null}}},
                  {"id": 811, "name": "Asia", "parent":
                    {"id": 81, "name": "Destinations", "parent":
                      {"id": 8, "name": "Travel", "parent": null}}},
                  {"id": 812, "name": "Europe", "parent":
                    {"id": 81, "name": "Destinations", "parent":
                      {"id": 8, "name": "Travel", "parent": null}}},
                  {"id": 813, "name": "Americas", "parent":
                    {"id": 81, "name": "Destinations", "parent":
                      {"id": 8, "name": "Travel", "parent": null}}},
                  {"id": 821, "name": "Airports", "parent":
                    {"id": 82, "name": "Airlines", "parent":
                      {"id": 8, "name": "Travel", "parent": null}}},
                  {"id": 831, "name": "Budget Stays", "parent":
                    {"id": 83, "name": "Hotels", "parent":
                      {"id": 8, "name": "Travel", "parent": null}}},
                  {"id": 832, "name": "Luxury Resorts", "parent":
                    {"id": 83, "name": "Hotels", "parent":
                      {"id": 8, "name": "Travel", "parent": null}}},
                  {"id": 911, "name": "Admissions", "parent":
                    {"id": 91, "name": "Universities", "parent":
                      {"id": 9, "name": "Education", "parent": null}}},
                  {"id": 912, "name": "Research Funding", "parent":
                    {"id": 91, "name": "Universities", "parent":
                      {"id": 9, "name": "Education", "parent": null}}},
                  {"id": 921, "name": "Curriculum", "parent":
                    {"id": 92, "name": "Schools", "parent":
                      {"id": 9, "name": "Education", "parent": null}}},
                  {"id": 922, "name": "Teachers", "parent":
                    {"id": 92, "name": "Schools", "parent":
                      {"id": 9, "name": "Education", "parent": null}}},
                  {"id": 931, "name": "MOOCs", "parent":
                    {"id": 93, "name": "Online Learning", "parent":
                      {"id": 9, "name": "Education", "parent": null}}},
                  {"id": 932, "name": "Language Apps", "parent":
                    {"id": 93, "name": "Online Learning", "parent":
                      {"id": 9, "name": "Education", "parent": null}}},
                  {"id": 1011, "name": "Recipes", "parent":
                    {"id": 101, "name": "Food & Drink", "parent":
                      {"id": 10, "name": "Lifestyle", "parent": null}}},
                  {"id": 1012, "name": "Restaurants", "parent":
                    {"id": 101, "name": "Food & Drink", "parent":
                      {"id": 10, "name": "Lifestyle", "parent": null}}},
                  {"id": 1021, "name": "Street Style", "parent":
                    {"id": 102, "name": "Fashion", "parent":
                      {"id": 10, "name": "Lifestyle", "parent": null}}},
                  {"id": 1031, "name": "Interior Design", "parent":
                    {"id": 103, "name": "Home & Garden", "parent":
                      {"id": 10, "name": "Lifestyle", "parent": null}}},
                  {"id": 1032, "name": "Gardening", "parent":
                    {"id": 103, "name": "Home & Garden", "parent":
                      {"id": 10, "name": "Lifestyle", "parent": null}}}
                ]
                """, STRICT));
    }
}
