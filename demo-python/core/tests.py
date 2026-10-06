"""Endpoint tests for the Django/DRF demo. Run: python manage.py test

Tests run against the real dataset in the repo-root demo.sqlite (built by db/generate.sql;
override the path with DEMO_DB). Django's test runner uses its own in-memory database, so
setUpTestData copies the schema and every row from a read-only connection to demo.sqlite
into it. The original file is never modified.
"""

import os
import sqlite3

from django.conf import settings
from django.db import connection
from rest_framework.test import APITestCase

DEMO_DB = os.environ.get('DEMO_DB') or str(settings.BASE_DIR.parent / 'demo.sqlite')


class EndpointTests(APITestCase):
    @classmethod
    def setUpTestData(cls):
        source = sqlite3.connect(f'file:{DEMO_DB}?mode=ro', uri=True)
        target = connection.connection  # the raw sqlite3 connection of the test database
        for (sql,) in source.execute(
            "select sql from sqlite_master where name in ('category', 'content', 'content_category_id')"
            " order by type desc, name"
        ):
            target.execute(sql)
        target.executemany(
            'insert into category (id, parent_id, name) values (?, ?, ?)',
            source.execute('select id, parent_id, name from category'),
        )
        target.executemany(
            'insert into content (id, category_id, content) values (?, ?, ?)',
            source.execute('select id, category_id, content from content'),
        )
        source.close()

    def test_list_default(self):
        response = self.client.get('/contents/')
        self.assertEqual(response.status_code, 200)
        # Ordered by id. There is no total count and there are no next/previous links.
        self.assertEqual(
            response.json(),
            {
                'page': 1,
                'page_size': 20,
                'results': [
                    {
                        'id': 1,
                        'category': {
                            'id': 91,
                            'name': 'Universities',
                            'parent': {'id': 9, 'name': 'Education', 'parent': None},
                        },
                        'content': 'Latest report: Universities #1',
                    },
                    {
                        'id': 2,
                        'category': {
                            'id': 321,
                            'name': 'NBA',
                            'parent': {
                                'id': 32,
                                'name': 'Basketball',
                                'parent': {'id': 3, 'name': 'Sports', 'parent': None},
                            },
                        },
                        'content': 'Analysis: NBA #2',
                    },
                    {
                        'id': 3,
                        'category': {
                            'id': 43,
                            'name': 'Economy',
                            'parent': {'id': 4, 'name': 'Business', 'parent': None},
                        },
                        'content': 'Opinion: Economy #3',
                    },
                    {
                        'id': 4,
                        'category': {
                            'id': 412,
                            'name': 'Commodities',
                            'parent': {
                                'id': 41,
                                'name': 'Markets',
                                'parent': {'id': 4, 'name': 'Business', 'parent': None},
                            },
                        },
                        'content': 'Explainer: Commodities #4',
                    },
                    {
                        'id': 5,
                        'category': {
                            'id': 1011,
                            'name': 'Recipes',
                            'parent': {
                                'id': 101,
                                'name': 'Food & Drink',
                                'parent': {'id': 10, 'name': 'Lifestyle', 'parent': None},
                            },
                        },
                        'content': 'Interview: Recipes #5',
                    },
                    {
                        'id': 6,
                        'category': {
                            'id': 62,
                            'name': 'Climate',
                            'parent': {'id': 6, 'name': 'Science', 'parent': None},
                        },
                        'content': 'Live updates: Climate #6',
                    },
                    {
                        'id': 7,
                        'category': {
                            'id': 431,
                            'name': 'Inflation',
                            'parent': {
                                'id': 43,
                                'name': 'Economy',
                                'parent': {'id': 4, 'name': 'Business', 'parent': None},
                            },
                        },
                        'content': 'Breaking news: Inflation #7',
                    },
                    {
                        'id': 8,
                        'category': {
                            'id': 522,
                            'name': 'Albums',
                            'parent': {
                                'id': 52,
                                'name': 'Music',
                                'parent': {'id': 5, 'name': 'Entertainment', 'parent': None},
                            },
                        },
                        'content': 'Latest report: Albums #8',
                    },
                    {
                        'id': 9,
                        'category': {
                            'id': 81,
                            'name': 'Destinations',
                            'parent': {'id': 8, 'name': 'Travel', 'parent': None},
                        },
                        'content': 'Analysis: Destinations #9',
                    },
                    {
                        'id': 10,
                        'category': {
                            'id': 311,
                            'name': 'Premier League',
                            'parent': {
                                'id': 31,
                                'name': 'Football',
                                'parent': {'id': 3, 'name': 'Sports', 'parent': None},
                            },
                        },
                        'content': 'Opinion: Premier League #10',
                    },
                    {
                        'id': 11,
                        'category': {'id': 33, 'name': 'Tennis', 'parent': {'id': 3, 'name': 'Sports', 'parent': None}},
                        'content': 'Explainer: Tennis #11',
                    },
                    {
                        'id': 12,
                        'category': {'id': 9, 'name': 'Education', 'parent': None},
                        'content': 'Interview: Education #12',
                    },
                    {
                        'id': 13,
                        'category': {
                            'id': 632,
                            'name': 'Neuroscience',
                            'parent': {
                                'id': 63,
                                'name': 'Biology',
                                'parent': {'id': 6, 'name': 'Science', 'parent': None},
                            },
                        },
                        'content': 'Live updates: Neuroscience #13',
                    },
                    {
                        'id': 14,
                        'category': {
                            'id': 52,
                            'name': 'Music',
                            'parent': {'id': 5, 'name': 'Entertainment', 'parent': None},
                        },
                        'content': 'Breaking news: Music #14',
                    },
                    {
                        'id': 15,
                        'category': {
                            'id': 421,
                            'name': 'Funding',
                            'parent': {
                                'id': 42,
                                'name': 'Startups',
                                'parent': {'id': 4, 'name': 'Business', 'parent': None},
                            },
                        },
                        'content': 'Latest report: Funding #15',
                    },
                    {
                        'id': 16,
                        'category': {'id': 4, 'name': 'Business', 'parent': None},
                        'content': 'Analysis: Business #16',
                    },
                    {
                        'id': 17,
                        'category': {
                            'id': 512,
                            'name': 'Film Festivals',
                            'parent': {
                                'id': 51,
                                'name': 'Movies',
                                'parent': {'id': 5, 'name': 'Entertainment', 'parent': None},
                            },
                        },
                        'content': 'Opinion: Film Festivals #17',
                    },
                    {
                        'id': 18,
                        'category': {
                            'id': 71,
                            'name': 'Fitness',
                            'parent': {'id': 7, 'name': 'Health', 'parent': None},
                        },
                        'content': 'Explainer: Fitness #18',
                    },
                    {
                        'id': 19,
                        'category': {
                            'id': 23,
                            'name': 'Software',
                            'parent': {'id': 2, 'name': 'Technology', 'parent': None},
                        },
                        'content': 'Interview: Software #19',
                    },
                    {
                        'id': 20,
                        'category': {
                            'id': 622,
                            'name': 'Renewable Energy',
                            'parent': {
                                'id': 62,
                                'name': 'Climate',
                                'parent': {'id': 6, 'name': 'Science', 'parent': None},
                            },
                        },
                        'content': 'Live updates: Renewable Energy #20',
                    },
                ],
            },
        )

    def test_list_page_2_size_2(self):
        response = self.client.get('/contents/?page=2&page_size=2')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'page': 2,
                'page_size': 2,
                'results': [
                    {
                        'id': 3,
                        'category': {
                            'id': 43,
                            'name': 'Economy',
                            'parent': {'id': 4, 'name': 'Business', 'parent': None},
                        },
                        'content': 'Opinion: Economy #3',
                    },
                    {
                        'id': 4,
                        'category': {
                            'id': 412,
                            'name': 'Commodities',
                            'parent': {
                                'id': 41,
                                'name': 'Markets',
                                'parent': {'id': 4, 'name': 'Business', 'parent': None},
                            },
                        },
                        'content': 'Explainer: Commodities #4',
                    },
                ],
            },
        )

    def test_list_past_the_end(self):
        response = self.client.get('/contents/?page=10000')
        # Past the end returns 200 with empty results (no COUNT query, so no 404).
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'page': 10000,
                'page_size': 20,
                'results': [],
            },
        )

    def test_list_size_zero(self):
        response = self.client.get('/contents/?page_size=0')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json(), {'page_size': ['Ensure this value is greater than or equal to 1.']})

    def test_item_in_root_category(self):
        response = self.client.get('/contents/12/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'id': 12,
                'category': {'id': 9, 'name': 'Education', 'parent': None},
                'content': 'Interview: Education #12',
            },
        )

    def test_item_in_level_2_category(self):
        response = self.client.get('/contents/1/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'id': 1,
                'category': {
                    'id': 91,
                    'name': 'Universities',
                    'parent': {'id': 9, 'name': 'Education', 'parent': None},
                },
                'content': 'Latest report: Universities #1',
            },
        )

    def test_item_in_level_3_category(self):
        response = self.client.get('/contents/2/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'id': 2,
                'category': {
                    'id': 321,
                    'name': 'NBA',
                    'parent': {'id': 32, 'name': 'Basketball', 'parent': {'id': 3, 'name': 'Sports', 'parent': None}},
                },
                'content': 'Analysis: NBA #2',
            },
        )

    def test_item_without_category(self):
        response = self.client.get('/contents/1000/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {'id': 1000, 'category': None, 'content': 'Uncategorized note 1000'})

    def test_item_not_found(self):
        response = self.client.get('/contents/100001/')
        self.assertEqual(response.status_code, 404)
        self.assertEqual(response.json(), {'detail': 'Not found.'})

    def test_item_non_numeric_id(self):
        response = self.client.get('/contents/abc/')
        self.assertEqual(response.status_code, 404)
        self.assertEqual(response.json(), {'detail': 'Not found.'})

    def test_update_content(self):
        response = self.client.put('/contents/2/', {'content': 'updated text'}, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'id': 2,
                'category': {
                    'id': 321,
                    'name': 'NBA',
                    'parent': {'id': 32, 'name': 'Basketball', 'parent': {'id': 3, 'name': 'Sports', 'parent': None}},
                },
                'content': 'updated text',
            },
        )

        response = self.client.get('/contents/2/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json(),
            {
                'id': 2,
                'category': {
                    'id': 321,
                    'name': 'NBA',
                    'parent': {'id': 32, 'name': 'Basketball', 'parent': {'id': 3, 'name': 'Sports', 'parent': None}},
                },
                'content': 'updated text',
            },
        )

    def test_update_empty_content(self):
        response = self.client.put('/contents/2/', {'content': ''}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json(), {'content': ['This field may not be blank.']})

    def test_update_missing_content_field(self):
        response = self.client.put('/contents/2/', {}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json(), {'content': ['This field is required.']})

    def test_update_malformed_json(self):
        response = self.client.put('/contents/2/', '{', content_type='application/json')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json(),
            {
                'detail': 'JSON parse error - Expecting property name enclosed in double quotes: line 1 column 2 (char 1)',
            },
        )

    def test_update_not_found(self):
        response = self.client.put('/contents/100001/', {'content': 'x'}, format='json')
        self.assertEqual(response.status_code, 404)
        self.assertEqual(response.json(), {'detail': 'Not found.'})

    def test_categories(self):
        response = self.client.get('/categories/')
        self.assertEqual(response.status_code, 200)
        # Not paginated: a plain array ordered by id; parent is the raw id, not nested.
        self.assertEqual(
            response.json(),
            [
                {'id': 1, 'parent': None, 'name': 'Politics'},
                {'id': 2, 'parent': None, 'name': 'Technology'},
                {'id': 3, 'parent': None, 'name': 'Sports'},
                {'id': 4, 'parent': None, 'name': 'Business'},
                {'id': 5, 'parent': None, 'name': 'Entertainment'},
                {'id': 6, 'parent': None, 'name': 'Science'},
                {'id': 7, 'parent': None, 'name': 'Health'},
                {'id': 8, 'parent': None, 'name': 'Travel'},
                {'id': 9, 'parent': None, 'name': 'Education'},
                {'id': 10, 'parent': None, 'name': 'Lifestyle'},
                {'id': 11, 'parent': 1, 'name': 'Elections'},
                {'id': 12, 'parent': 1, 'name': 'Policy'},
                {'id': 13, 'parent': 1, 'name': 'Diplomacy'},
                {'id': 21, 'parent': 2, 'name': 'Artificial Intelligence'},
                {'id': 22, 'parent': 2, 'name': 'Hardware'},
                {'id': 23, 'parent': 2, 'name': 'Software'},
                {'id': 31, 'parent': 3, 'name': 'Football'},
                {'id': 32, 'parent': 3, 'name': 'Basketball'},
                {'id': 33, 'parent': 3, 'name': 'Tennis'},
                {'id': 41, 'parent': 4, 'name': 'Markets'},
                {'id': 42, 'parent': 4, 'name': 'Startups'},
                {'id': 43, 'parent': 4, 'name': 'Economy'},
                {'id': 51, 'parent': 5, 'name': 'Movies'},
                {'id': 52, 'parent': 5, 'name': 'Music'},
                {'id': 53, 'parent': 5, 'name': 'Television'},
                {'id': 61, 'parent': 6, 'name': 'Space'},
                {'id': 62, 'parent': 6, 'name': 'Climate'},
                {'id': 63, 'parent': 6, 'name': 'Biology'},
                {'id': 71, 'parent': 7, 'name': 'Fitness'},
                {'id': 72, 'parent': 7, 'name': 'Nutrition'},
                {'id': 73, 'parent': 7, 'name': 'Medicine'},
                {'id': 81, 'parent': 8, 'name': 'Destinations'},
                {'id': 82, 'parent': 8, 'name': 'Airlines'},
                {'id': 83, 'parent': 8, 'name': 'Hotels'},
                {'id': 91, 'parent': 9, 'name': 'Universities'},
                {'id': 92, 'parent': 9, 'name': 'Schools'},
                {'id': 93, 'parent': 9, 'name': 'Online Learning'},
                {'id': 101, 'parent': 10, 'name': 'Food & Drink'},
                {'id': 102, 'parent': 10, 'name': 'Fashion'},
                {'id': 103, 'parent': 10, 'name': 'Home & Garden'},
                {'id': 111, 'parent': 11, 'name': 'US Elections'},
                {'id': 112, 'parent': 11, 'name': 'EU Elections'},
                {'id': 113, 'parent': 11, 'name': 'Local Elections'},
                {'id': 121, 'parent': 12, 'name': 'Healthcare Policy'},
                {'id': 122, 'parent': 12, 'name': 'Tax Policy'},
                {'id': 131, 'parent': 13, 'name': 'Trade Agreements'},
                {'id': 211, 'parent': 21, 'name': 'Large Language Models'},
                {'id': 212, 'parent': 21, 'name': 'Computer Vision'},
                {'id': 213, 'parent': 21, 'name': 'Robotics'},
                {'id': 221, 'parent': 22, 'name': 'Chips'},
                {'id': 222, 'parent': 22, 'name': 'Smartphones'},
                {'id': 231, 'parent': 23, 'name': 'Open Source'},
                {'id': 232, 'parent': 23, 'name': 'Cloud Computing'},
                {'id': 311, 'parent': 31, 'name': 'Premier League'},
                {'id': 312, 'parent': 31, 'name': 'Champions League'},
                {'id': 313, 'parent': 31, 'name': 'La Liga'},
                {'id': 321, 'parent': 32, 'name': 'NBA'},
                {'id': 322, 'parent': 32, 'name': 'EuroLeague'},
                {'id': 331, 'parent': 33, 'name': 'Grand Slams'},
                {'id': 411, 'parent': 41, 'name': 'Stocks'},
                {'id': 412, 'parent': 41, 'name': 'Commodities'},
                {'id': 413, 'parent': 41, 'name': 'Crypto'},
                {'id': 421, 'parent': 42, 'name': 'Funding'},
                {'id': 422, 'parent': 42, 'name': 'Acquisitions'},
                {'id': 431, 'parent': 43, 'name': 'Inflation'},
                {'id': 432, 'parent': 43, 'name': 'Employment'},
                {'id': 511, 'parent': 51, 'name': 'Box Office'},
                {'id': 512, 'parent': 51, 'name': 'Film Festivals'},
                {'id': 513, 'parent': 51, 'name': 'Animation'},
                {'id': 521, 'parent': 52, 'name': 'Concerts'},
                {'id': 522, 'parent': 52, 'name': 'Albums'},
                {'id': 611, 'parent': 61, 'name': 'Mars Missions'},
                {'id': 612, 'parent': 61, 'name': 'Telescopes'},
                {'id': 621, 'parent': 62, 'name': 'Extreme Weather'},
                {'id': 622, 'parent': 62, 'name': 'Renewable Energy'},
                {'id': 631, 'parent': 63, 'name': 'Genetics'},
                {'id': 632, 'parent': 63, 'name': 'Neuroscience'},
                {'id': 711, 'parent': 71, 'name': 'Running'},
                {'id': 712, 'parent': 71, 'name': 'Strength Training'},
                {'id': 721, 'parent': 72, 'name': 'Diets'},
                {'id': 722, 'parent': 72, 'name': 'Supplements'},
                {'id': 731, 'parent': 73, 'name': 'Vaccines'},
                {'id': 732, 'parent': 73, 'name': 'Mental Health'},
                {'id': 811, 'parent': 81, 'name': 'Asia'},
                {'id': 812, 'parent': 81, 'name': 'Europe'},
                {'id': 813, 'parent': 81, 'name': 'Americas'},
                {'id': 821, 'parent': 82, 'name': 'Airports'},
                {'id': 831, 'parent': 83, 'name': 'Budget Stays'},
                {'id': 832, 'parent': 83, 'name': 'Luxury Resorts'},
                {'id': 911, 'parent': 91, 'name': 'Admissions'},
                {'id': 912, 'parent': 91, 'name': 'Research Funding'},
                {'id': 921, 'parent': 92, 'name': 'Curriculum'},
                {'id': 922, 'parent': 92, 'name': 'Teachers'},
                {'id': 931, 'parent': 93, 'name': 'MOOCs'},
                {'id': 932, 'parent': 93, 'name': 'Language Apps'},
                {'id': 1011, 'parent': 101, 'name': 'Recipes'},
                {'id': 1012, 'parent': 101, 'name': 'Restaurants'},
                {'id': 1021, 'parent': 102, 'name': 'Street Style'},
                {'id': 1031, 'parent': 103, 'name': 'Interior Design'},
                {'id': 1032, 'parent': 103, 'name': 'Gardening'},
            ],
        )
