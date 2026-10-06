using Xunit;

namespace DemoDotnet.Tests;

// The same 16 cases exist in every demo of this repo, so two demos can be read side by side.
// Each test runs against a fresh copy of the repo-root demo.sqlite (see ApiFactory.ResetData).
// Every nested category carries its parent chain all the way up to the root.
[Collection(ApiCollection.Name)]
public sealed class ApiTests(ApiFactory factory) : ApiTestBase(factory)
{
    [Fact]
    public async Task ListDefault()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents");

        Assert.Equal(200, status);
        AssertJsonEquals("""
            {
              "page": 1,
              "size": 20,
              "contents": [
                {"id": 1, "category_id": 91, "content": "Latest report: Universities #1", "category": {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
                {"id": 2, "category_id": 321, "content": "Analysis: NBA #2", "category": {"id": 321, "parent_id": 32, "name": "NBA", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 3, "category_id": 43, "content": "Opinion: Economy #3", "category": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
                {"id": 4, "category_id": 412, "content": "Explainer: Commodities #4", "category": {"id": 412, "parent_id": 41, "name": "Commodities", "parent": {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 5, "category_id": 1011, "content": "Interview: Recipes #5", "category": {"id": 1011, "parent_id": 101, "name": "Recipes", "parent": {"id": 101, "parent_id": 10, "name": "Food & Drink", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}}},
                {"id": 6, "category_id": 62, "content": "Live updates: Climate #6", "category": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
                {"id": 7, "category_id": 431, "content": "Breaking news: Inflation #7", "category": {"id": 431, "parent_id": 43, "name": "Inflation", "parent": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 8, "category_id": 522, "content": "Latest report: Albums #8", "category": {"id": 522, "parent_id": 52, "name": "Albums", "parent": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 9, "category_id": 81, "content": "Analysis: Destinations #9", "category": {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
                {"id": 10, "category_id": 311, "content": "Opinion: Premier League #10", "category": {"id": 311, "parent_id": 31, "name": "Premier League", "parent": {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 11, "category_id": 33, "content": "Explainer: Tennis #11", "category": {"id": 33, "parent_id": 3, "name": "Tennis", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
                {"id": 12, "category_id": 9, "content": "Interview: Education #12", "category": {"id": 9, "parent_id": null, "name": "Education", "parent": null}},
                {"id": 13, "category_id": 632, "content": "Live updates: Neuroscience #13", "category": {"id": 632, "parent_id": 63, "name": "Neuroscience", "parent": {"id": 63, "parent_id": 6, "name": "Biology", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}},
                {"id": 14, "category_id": 52, "content": "Breaking news: Music #14", "category": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
                {"id": 15, "category_id": 421, "content": "Latest report: Funding #15", "category": {"id": 421, "parent_id": 42, "name": "Funding", "parent": {"id": 42, "parent_id": 4, "name": "Startups", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 16, "category_id": 4, "content": "Analysis: Business #16", "category": {"id": 4, "parent_id": null, "name": "Business", "parent": null}},
                {"id": 17, "category_id": 512, "content": "Opinion: Film Festivals #17", "category": {"id": 512, "parent_id": 51, "name": "Film Festivals", "parent": {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 18, "category_id": 71, "content": "Explainer: Fitness #18", "category": {"id": 71, "parent_id": 7, "name": "Fitness", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
                {"id": 19, "category_id": 23, "content": "Interview: Software #19", "category": {"id": 23, "parent_id": 2, "name": "Software", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
                {"id": 20, "category_id": 622, "content": "Live updates: Renewable Energy #20", "category": {"id": 622, "parent_id": 62, "name": "Renewable Energy", "parent": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}}
              ]
            }
            """, json);
    }

    [Fact]
    public async Task ListPage2Size2()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents?page=2&size=2");

        Assert.Equal(200, status);
        // Surprising (bug): any `page` query key makes MVC bind the PageQuery parameter (also named `page`)
        // with the prefix "page.", so page AND size are ignored and the defaults (page 1, size 20) apply.
        AssertJsonEquals("""
            {
              "page": 1,
              "size": 20,
              "contents": [
                {"id": 1, "category_id": 91, "content": "Latest report: Universities #1", "category": {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
                {"id": 2, "category_id": 321, "content": "Analysis: NBA #2", "category": {"id": 321, "parent_id": 32, "name": "NBA", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 3, "category_id": 43, "content": "Opinion: Economy #3", "category": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
                {"id": 4, "category_id": 412, "content": "Explainer: Commodities #4", "category": {"id": 412, "parent_id": 41, "name": "Commodities", "parent": {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 5, "category_id": 1011, "content": "Interview: Recipes #5", "category": {"id": 1011, "parent_id": 101, "name": "Recipes", "parent": {"id": 101, "parent_id": 10, "name": "Food & Drink", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}}},
                {"id": 6, "category_id": 62, "content": "Live updates: Climate #6", "category": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
                {"id": 7, "category_id": 431, "content": "Breaking news: Inflation #7", "category": {"id": 431, "parent_id": 43, "name": "Inflation", "parent": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 8, "category_id": 522, "content": "Latest report: Albums #8", "category": {"id": 522, "parent_id": 52, "name": "Albums", "parent": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 9, "category_id": 81, "content": "Analysis: Destinations #9", "category": {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
                {"id": 10, "category_id": 311, "content": "Opinion: Premier League #10", "category": {"id": 311, "parent_id": 31, "name": "Premier League", "parent": {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 11, "category_id": 33, "content": "Explainer: Tennis #11", "category": {"id": 33, "parent_id": 3, "name": "Tennis", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
                {"id": 12, "category_id": 9, "content": "Interview: Education #12", "category": {"id": 9, "parent_id": null, "name": "Education", "parent": null}},
                {"id": 13, "category_id": 632, "content": "Live updates: Neuroscience #13", "category": {"id": 632, "parent_id": 63, "name": "Neuroscience", "parent": {"id": 63, "parent_id": 6, "name": "Biology", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}},
                {"id": 14, "category_id": 52, "content": "Breaking news: Music #14", "category": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
                {"id": 15, "category_id": 421, "content": "Latest report: Funding #15", "category": {"id": 421, "parent_id": 42, "name": "Funding", "parent": {"id": 42, "parent_id": 4, "name": "Startups", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 16, "category_id": 4, "content": "Analysis: Business #16", "category": {"id": 4, "parent_id": null, "name": "Business", "parent": null}},
                {"id": 17, "category_id": 512, "content": "Opinion: Film Festivals #17", "category": {"id": 512, "parent_id": 51, "name": "Film Festivals", "parent": {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 18, "category_id": 71, "content": "Explainer: Fitness #18", "category": {"id": 71, "parent_id": 7, "name": "Fitness", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
                {"id": 19, "category_id": 23, "content": "Interview: Software #19", "category": {"id": 23, "parent_id": 2, "name": "Software", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
                {"id": 20, "category_id": 622, "content": "Live updates: Renewable Energy #20", "category": {"id": 622, "parent_id": 62, "name": "Renewable Energy", "parent": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}}
              ]
            }
            """, json);
    }

    [Fact]
    public async Task ListPastTheEnd()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents?page=10000");

        Assert.Equal(200, status);
        // Surprising (bug): the `page` query key is ignored (same binding-prefix issue as ListPage2Size2),
        // so this returns page 1 instead of an empty page 10000.
        AssertJsonEquals("""
            {
              "page": 1,
              "size": 20,
              "contents": [
                {"id": 1, "category_id": 91, "content": "Latest report: Universities #1", "category": {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
                {"id": 2, "category_id": 321, "content": "Analysis: NBA #2", "category": {"id": 321, "parent_id": 32, "name": "NBA", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 3, "category_id": 43, "content": "Opinion: Economy #3", "category": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
                {"id": 4, "category_id": 412, "content": "Explainer: Commodities #4", "category": {"id": 412, "parent_id": 41, "name": "Commodities", "parent": {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 5, "category_id": 1011, "content": "Interview: Recipes #5", "category": {"id": 1011, "parent_id": 101, "name": "Recipes", "parent": {"id": 101, "parent_id": 10, "name": "Food & Drink", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}}},
                {"id": 6, "category_id": 62, "content": "Live updates: Climate #6", "category": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
                {"id": 7, "category_id": 431, "content": "Breaking news: Inflation #7", "category": {"id": 431, "parent_id": 43, "name": "Inflation", "parent": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 8, "category_id": 522, "content": "Latest report: Albums #8", "category": {"id": 522, "parent_id": 52, "name": "Albums", "parent": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 9, "category_id": 81, "content": "Analysis: Destinations #9", "category": {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
                {"id": 10, "category_id": 311, "content": "Opinion: Premier League #10", "category": {"id": 311, "parent_id": 31, "name": "Premier League", "parent": {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 11, "category_id": 33, "content": "Explainer: Tennis #11", "category": {"id": 33, "parent_id": 3, "name": "Tennis", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
                {"id": 12, "category_id": 9, "content": "Interview: Education #12", "category": {"id": 9, "parent_id": null, "name": "Education", "parent": null}},
                {"id": 13, "category_id": 632, "content": "Live updates: Neuroscience #13", "category": {"id": 632, "parent_id": 63, "name": "Neuroscience", "parent": {"id": 63, "parent_id": 6, "name": "Biology", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}},
                {"id": 14, "category_id": 52, "content": "Breaking news: Music #14", "category": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
                {"id": 15, "category_id": 421, "content": "Latest report: Funding #15", "category": {"id": 421, "parent_id": 42, "name": "Funding", "parent": {"id": 42, "parent_id": 4, "name": "Startups", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 16, "category_id": 4, "content": "Analysis: Business #16", "category": {"id": 4, "parent_id": null, "name": "Business", "parent": null}},
                {"id": 17, "category_id": 512, "content": "Opinion: Film Festivals #17", "category": {"id": 512, "parent_id": 51, "name": "Film Festivals", "parent": {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 18, "category_id": 71, "content": "Explainer: Fitness #18", "category": {"id": 71, "parent_id": 7, "name": "Fitness", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
                {"id": 19, "category_id": 23, "content": "Interview: Software #19", "category": {"id": 23, "parent_id": 2, "name": "Software", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
                {"id": 20, "category_id": 622, "content": "Live updates: Renewable Energy #20", "category": {"id": 622, "parent_id": 62, "name": "Renewable Energy", "parent": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}}
              ]
            }
            """, json);
    }

    [Fact]
    public async Task ListSizeZero()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents?size=0");

        Assert.Equal(200, status);
        // size <= 0 falls back to the default size 20.
        AssertJsonEquals("""
            {
              "page": 1,
              "size": 20,
              "contents": [
                {"id": 1, "category_id": 91, "content": "Latest report: Universities #1", "category": {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
                {"id": 2, "category_id": 321, "content": "Analysis: NBA #2", "category": {"id": 321, "parent_id": 32, "name": "NBA", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 3, "category_id": 43, "content": "Opinion: Economy #3", "category": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
                {"id": 4, "category_id": 412, "content": "Explainer: Commodities #4", "category": {"id": 412, "parent_id": 41, "name": "Commodities", "parent": {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 5, "category_id": 1011, "content": "Interview: Recipes #5", "category": {"id": 1011, "parent_id": 101, "name": "Recipes", "parent": {"id": 101, "parent_id": 10, "name": "Food & Drink", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}}},
                {"id": 6, "category_id": 62, "content": "Live updates: Climate #6", "category": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
                {"id": 7, "category_id": 431, "content": "Breaking news: Inflation #7", "category": {"id": 431, "parent_id": 43, "name": "Inflation", "parent": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 8, "category_id": 522, "content": "Latest report: Albums #8", "category": {"id": 522, "parent_id": 52, "name": "Albums", "parent": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 9, "category_id": 81, "content": "Analysis: Destinations #9", "category": {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
                {"id": 10, "category_id": 311, "content": "Opinion: Premier League #10", "category": {"id": 311, "parent_id": 31, "name": "Premier League", "parent": {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}},
                {"id": 11, "category_id": 33, "content": "Explainer: Tennis #11", "category": {"id": 33, "parent_id": 3, "name": "Tennis", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
                {"id": 12, "category_id": 9, "content": "Interview: Education #12", "category": {"id": 9, "parent_id": null, "name": "Education", "parent": null}},
                {"id": 13, "category_id": 632, "content": "Live updates: Neuroscience #13", "category": {"id": 632, "parent_id": 63, "name": "Neuroscience", "parent": {"id": 63, "parent_id": 6, "name": "Biology", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}},
                {"id": 14, "category_id": 52, "content": "Breaking news: Music #14", "category": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
                {"id": 15, "category_id": 421, "content": "Latest report: Funding #15", "category": {"id": 421, "parent_id": 42, "name": "Funding", "parent": {"id": 42, "parent_id": 4, "name": "Startups", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}}},
                {"id": 16, "category_id": 4, "content": "Analysis: Business #16", "category": {"id": 4, "parent_id": null, "name": "Business", "parent": null}},
                {"id": 17, "category_id": 512, "content": "Opinion: Film Festivals #17", "category": {"id": 512, "parent_id": 51, "name": "Film Festivals", "parent": {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}}},
                {"id": 18, "category_id": 71, "content": "Explainer: Fitness #18", "category": {"id": 71, "parent_id": 7, "name": "Fitness", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
                {"id": 19, "category_id": 23, "content": "Interview: Software #19", "category": {"id": 23, "parent_id": 2, "name": "Software", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
                {"id": 20, "category_id": 622, "content": "Live updates: Renewable Energy #20", "category": {"id": 622, "parent_id": 62, "name": "Renewable Energy", "parent": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}}}
              ]
            }
            """, json);
    }

    [Fact]
    public async Task ItemInRootCategory()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents/12");

        Assert.Equal(200, status);
        AssertJsonEquals("""
            {"id": 12, "category_id": 9, "content": "Interview: Education #12", "category": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}
            """, json);
    }

    [Fact]
    public async Task ItemInLevel2Category()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents/1");

        Assert.Equal(200, status);
        AssertJsonEquals("""
            {"id": 1, "category_id": 91, "content": "Latest report: Universities #1", "category": {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}}
            """, json);
    }

    [Fact]
    public async Task ItemInLevel3Category()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents/2");

        Assert.Equal(200, status);
        AssertJsonEquals("""
            {"id": 2, "category_id": 321, "content": "Analysis: NBA #2", "category": {"id": 321, "parent_id": 32, "name": "NBA", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}}
            """, json);
    }

    [Fact]
    public async Task ItemWithoutCategory()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/contents/1000");

        Assert.Equal(200, status);
        AssertJsonEquals("""
            {"id": 1000, "category_id": null, "content": "Uncategorized note 1000", "category": null}
            """, json);
    }

    [Fact]
    public async Task ItemNotFound()
    {
        var (status, body, _) = await Send(HttpMethod.Get, "/api/contents/100001");

        Assert.Equal(404, status);
        // Surprising: the 404 body is plain text (text/plain), not JSON.
        Assert.Equal("content not found", body);
    }

    [Fact]
    public async Task ItemNonNumericId()
    {
        var (status, body, _) = await Send(HttpMethod.Get, "/api/contents/abc");

        // The {id:int} route constraint does not match, so routing returns 404 with an empty body.
        Assert.Equal(404, status);
        Assert.Equal("", body);
    }

    [Fact]
    public async Task UpdateContent()
    {
        var (status, _, json) = await Send(HttpMethod.Put, "/api/contents/2", """{"content":"updated text"}""");

        Assert.Equal(200, status);
        // Surprising: the PUT response has "category": null although category_id is 321, because the
        // updated entity is loaded without Include() before mapping. The GET below shows the real category.
        AssertJsonEquals("""
            {"id": 2, "category_id": 321, "content": "updated text", "category": null}
            """, json);

        var (getStatus, _, getJson) = await Send(HttpMethod.Get, "/api/contents/2");

        Assert.Equal(200, getStatus);
        AssertJsonEquals("""
            {"id": 2, "category_id": 321, "content": "updated text", "category": {"id": 321, "parent_id": 32, "name": "NBA", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}}}
            """, getJson);
    }

    [Fact]
    public async Task UpdateEmptyContent()
    {
        var (status, _, json) = await Send(HttpMethod.Put, "/api/contents/2", """{"content":""}""");

        Assert.Equal(400, status);
        // FluentValidation messages, returned as a bare JSON array of strings.
        AssertJsonEquals("""
            ["'Content' must not be empty."]
            """, json);
    }

    [Fact]
    public async Task UpdateMissingContentField()
    {
        var (status, _, json) = await Send(HttpMethod.Put, "/api/contents/2", "{}");

        Assert.Equal(400, status);
        // ASP.NET's automatic ValidationProblemDetails (not the FluentValidation array). traceId differs
        // per request, so check it is present and drop it before comparing the rest.
        Assert.False(string.IsNullOrEmpty((string?)json!["traceId"]));
        json.AsObject().Remove("traceId");
        AssertJsonEquals("""
            {
              "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
              "title": "One or more validation errors occurred.",
              "status": 400,
              "errors": {"Content": ["The Content field is required."]}
            }
            """, json);
    }

    [Fact]
    public async Task UpdateMalformedJson()
    {
        var (status, _, json) = await Send(HttpMethod.Put, "/api/contents/2", "{");

        Assert.Equal(400, status);
        // ASP.NET's automatic ValidationProblemDetails. traceId differs per request, so check it is
        // present and drop it before comparing the rest.
        Assert.False(string.IsNullOrEmpty((string?)json!["traceId"]));
        json.AsObject().Remove("traceId");
        AssertJsonEquals("""
            {
              "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
              "title": "One or more validation errors occurred.",
              "status": 400,
              "errors": {
                "$": ["Expected depth to be zero at the end of the JSON payload. There is an open JSON object or array that should be closed. Path: $ | LineNumber: 0 | BytePositionInLine: 1."],
                "body": ["The body field is required."]
              }
            }
            """, json);
    }

    [Fact]
    public async Task UpdateNotFound()
    {
        var (status, body, _) = await Send(HttpMethod.Put, "/api/contents/100001", """{"content":"x"}""");

        Assert.Equal(404, status);
        // Surprising: the 404 body is plain text (text/plain), not JSON.
        Assert.Equal("content not found", body);
    }

    [Fact]
    public async Task Categories()
    {
        var (status, _, json) = await Send(HttpMethod.Get, "/api/categories");

        Assert.Equal(200, status);
        AssertJsonEquals("""
            [
              {"id": 1, "parent_id": null, "name": "Politics", "parent": null},
              {"id": 2, "parent_id": null, "name": "Technology", "parent": null},
              {"id": 3, "parent_id": null, "name": "Sports", "parent": null},
              {"id": 4, "parent_id": null, "name": "Business", "parent": null},
              {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null},
              {"id": 6, "parent_id": null, "name": "Science", "parent": null},
              {"id": 7, "parent_id": null, "name": "Health", "parent": null},
              {"id": 8, "parent_id": null, "name": "Travel", "parent": null},
              {"id": 9, "parent_id": null, "name": "Education", "parent": null},
              {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null},
              {"id": 11, "parent_id": 1, "name": "Elections", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}},
              {"id": 12, "parent_id": 1, "name": "Policy", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}},
              {"id": 13, "parent_id": 1, "name": "Diplomacy", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}},
              {"id": 21, "parent_id": 2, "name": "Artificial Intelligence", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}},
              {"id": 22, "parent_id": 2, "name": "Hardware", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}},
              {"id": 23, "parent_id": 2, "name": "Software", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}},
              {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}},
              {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}},
              {"id": 33, "parent_id": 3, "name": "Tennis", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}},
              {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}},
              {"id": 42, "parent_id": 4, "name": "Startups", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}},
              {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}},
              {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}},
              {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}},
              {"id": 53, "parent_id": 5, "name": "Television", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}},
              {"id": 61, "parent_id": 6, "name": "Space", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}},
              {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}},
              {"id": 63, "parent_id": 6, "name": "Biology", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}},
              {"id": 71, "parent_id": 7, "name": "Fitness", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}},
              {"id": 72, "parent_id": 7, "name": "Nutrition", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}},
              {"id": 73, "parent_id": 7, "name": "Medicine", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}},
              {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}},
              {"id": 82, "parent_id": 8, "name": "Airlines", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}},
              {"id": 83, "parent_id": 8, "name": "Hotels", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}},
              {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}},
              {"id": 92, "parent_id": 9, "name": "Schools", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}},
              {"id": 93, "parent_id": 9, "name": "Online Learning", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}},
              {"id": 101, "parent_id": 10, "name": "Food & Drink", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}},
              {"id": 102, "parent_id": 10, "name": "Fashion", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}},
              {"id": 103, "parent_id": 10, "name": "Home & Garden", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}},
              {"id": 111, "parent_id": 11, "name": "US Elections", "parent": {"id": 11, "parent_id": 1, "name": "Elections", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}}},
              {"id": 112, "parent_id": 11, "name": "EU Elections", "parent": {"id": 11, "parent_id": 1, "name": "Elections", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}}},
              {"id": 113, "parent_id": 11, "name": "Local Elections", "parent": {"id": 11, "parent_id": 1, "name": "Elections", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}}},
              {"id": 121, "parent_id": 12, "name": "Healthcare Policy", "parent": {"id": 12, "parent_id": 1, "name": "Policy", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}}},
              {"id": 122, "parent_id": 12, "name": "Tax Policy", "parent": {"id": 12, "parent_id": 1, "name": "Policy", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}}},
              {"id": 131, "parent_id": 13, "name": "Trade Agreements", "parent": {"id": 13, "parent_id": 1, "name": "Diplomacy", "parent": {"id": 1, "parent_id": null, "name": "Politics", "parent": null}}},
              {"id": 211, "parent_id": 21, "name": "Large Language Models", "parent": {"id": 21, "parent_id": 2, "name": "Artificial Intelligence", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
              {"id": 212, "parent_id": 21, "name": "Computer Vision", "parent": {"id": 21, "parent_id": 2, "name": "Artificial Intelligence", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
              {"id": 213, "parent_id": 21, "name": "Robotics", "parent": {"id": 21, "parent_id": 2, "name": "Artificial Intelligence", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
              {"id": 221, "parent_id": 22, "name": "Chips", "parent": {"id": 22, "parent_id": 2, "name": "Hardware", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
              {"id": 222, "parent_id": 22, "name": "Smartphones", "parent": {"id": 22, "parent_id": 2, "name": "Hardware", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
              {"id": 231, "parent_id": 23, "name": "Open Source", "parent": {"id": 23, "parent_id": 2, "name": "Software", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
              {"id": 232, "parent_id": 23, "name": "Cloud Computing", "parent": {"id": 23, "parent_id": 2, "name": "Software", "parent": {"id": 2, "parent_id": null, "name": "Technology", "parent": null}}},
              {"id": 311, "parent_id": 31, "name": "Premier League", "parent": {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
              {"id": 312, "parent_id": 31, "name": "Champions League", "parent": {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
              {"id": 313, "parent_id": 31, "name": "La Liga", "parent": {"id": 31, "parent_id": 3, "name": "Football", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
              {"id": 321, "parent_id": 32, "name": "NBA", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
              {"id": 322, "parent_id": 32, "name": "EuroLeague", "parent": {"id": 32, "parent_id": 3, "name": "Basketball", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
              {"id": 331, "parent_id": 33, "name": "Grand Slams", "parent": {"id": 33, "parent_id": 3, "name": "Tennis", "parent": {"id": 3, "parent_id": null, "name": "Sports", "parent": null}}},
              {"id": 411, "parent_id": 41, "name": "Stocks", "parent": {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
              {"id": 412, "parent_id": 41, "name": "Commodities", "parent": {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
              {"id": 413, "parent_id": 41, "name": "Crypto", "parent": {"id": 41, "parent_id": 4, "name": "Markets", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
              {"id": 421, "parent_id": 42, "name": "Funding", "parent": {"id": 42, "parent_id": 4, "name": "Startups", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
              {"id": 422, "parent_id": 42, "name": "Acquisitions", "parent": {"id": 42, "parent_id": 4, "name": "Startups", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
              {"id": 431, "parent_id": 43, "name": "Inflation", "parent": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
              {"id": 432, "parent_id": 43, "name": "Employment", "parent": {"id": 43, "parent_id": 4, "name": "Economy", "parent": {"id": 4, "parent_id": null, "name": "Business", "parent": null}}},
              {"id": 511, "parent_id": 51, "name": "Box Office", "parent": {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
              {"id": 512, "parent_id": 51, "name": "Film Festivals", "parent": {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
              {"id": 513, "parent_id": 51, "name": "Animation", "parent": {"id": 51, "parent_id": 5, "name": "Movies", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
              {"id": 521, "parent_id": 52, "name": "Concerts", "parent": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
              {"id": 522, "parent_id": 52, "name": "Albums", "parent": {"id": 52, "parent_id": 5, "name": "Music", "parent": {"id": 5, "parent_id": null, "name": "Entertainment", "parent": null}}},
              {"id": 611, "parent_id": 61, "name": "Mars Missions", "parent": {"id": 61, "parent_id": 6, "name": "Space", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
              {"id": 612, "parent_id": 61, "name": "Telescopes", "parent": {"id": 61, "parent_id": 6, "name": "Space", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
              {"id": 621, "parent_id": 62, "name": "Extreme Weather", "parent": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
              {"id": 622, "parent_id": 62, "name": "Renewable Energy", "parent": {"id": 62, "parent_id": 6, "name": "Climate", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
              {"id": 631, "parent_id": 63, "name": "Genetics", "parent": {"id": 63, "parent_id": 6, "name": "Biology", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
              {"id": 632, "parent_id": 63, "name": "Neuroscience", "parent": {"id": 63, "parent_id": 6, "name": "Biology", "parent": {"id": 6, "parent_id": null, "name": "Science", "parent": null}}},
              {"id": 711, "parent_id": 71, "name": "Running", "parent": {"id": 71, "parent_id": 7, "name": "Fitness", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
              {"id": 712, "parent_id": 71, "name": "Strength Training", "parent": {"id": 71, "parent_id": 7, "name": "Fitness", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
              {"id": 721, "parent_id": 72, "name": "Diets", "parent": {"id": 72, "parent_id": 7, "name": "Nutrition", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
              {"id": 722, "parent_id": 72, "name": "Supplements", "parent": {"id": 72, "parent_id": 7, "name": "Nutrition", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
              {"id": 731, "parent_id": 73, "name": "Vaccines", "parent": {"id": 73, "parent_id": 7, "name": "Medicine", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
              {"id": 732, "parent_id": 73, "name": "Mental Health", "parent": {"id": 73, "parent_id": 7, "name": "Medicine", "parent": {"id": 7, "parent_id": null, "name": "Health", "parent": null}}},
              {"id": 811, "parent_id": 81, "name": "Asia", "parent": {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
              {"id": 812, "parent_id": 81, "name": "Europe", "parent": {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
              {"id": 813, "parent_id": 81, "name": "Americas", "parent": {"id": 81, "parent_id": 8, "name": "Destinations", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
              {"id": 821, "parent_id": 82, "name": "Airports", "parent": {"id": 82, "parent_id": 8, "name": "Airlines", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
              {"id": 831, "parent_id": 83, "name": "Budget Stays", "parent": {"id": 83, "parent_id": 8, "name": "Hotels", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
              {"id": 832, "parent_id": 83, "name": "Luxury Resorts", "parent": {"id": 83, "parent_id": 8, "name": "Hotels", "parent": {"id": 8, "parent_id": null, "name": "Travel", "parent": null}}},
              {"id": 911, "parent_id": 91, "name": "Admissions", "parent": {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
              {"id": 912, "parent_id": 91, "name": "Research Funding", "parent": {"id": 91, "parent_id": 9, "name": "Universities", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
              {"id": 921, "parent_id": 92, "name": "Curriculum", "parent": {"id": 92, "parent_id": 9, "name": "Schools", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
              {"id": 922, "parent_id": 92, "name": "Teachers", "parent": {"id": 92, "parent_id": 9, "name": "Schools", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
              {"id": 931, "parent_id": 93, "name": "MOOCs", "parent": {"id": 93, "parent_id": 9, "name": "Online Learning", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
              {"id": 932, "parent_id": 93, "name": "Language Apps", "parent": {"id": 93, "parent_id": 9, "name": "Online Learning", "parent": {"id": 9, "parent_id": null, "name": "Education", "parent": null}}},
              {"id": 1011, "parent_id": 101, "name": "Recipes", "parent": {"id": 101, "parent_id": 10, "name": "Food & Drink", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}},
              {"id": 1012, "parent_id": 101, "name": "Restaurants", "parent": {"id": 101, "parent_id": 10, "name": "Food & Drink", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}},
              {"id": 1021, "parent_id": 102, "name": "Street Style", "parent": {"id": 102, "parent_id": 10, "name": "Fashion", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}},
              {"id": 1031, "parent_id": 103, "name": "Interior Design", "parent": {"id": 103, "parent_id": 10, "name": "Home & Garden", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}},
              {"id": 1032, "parent_id": 103, "name": "Gardening", "parent": {"id": 103, "parent_id": 10, "name": "Home & Garden", "parent": {"id": 10, "parent_id": null, "name": "Lifestyle", "parent": null}}}
            ]
            """, json);
    }
}
