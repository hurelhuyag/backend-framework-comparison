// Weighted mixed read load for the framework comparison.
//
// Driven entirely by env vars so one script serves every framework, each of which spells its
// endpoints differently (/api prefix, size vs page_size vs pageSize, Django trailing slashes).
// Concurrency and request count come from the CLI: --vus N --iterations M.
import http from 'k6/http';

const BASE = __ENV.BASE;
const LIST_PATH = __ENV.LIST_PATH;
const ITEM_PATH = __ENV.ITEM_PATH;
const CATEGORIES_PATH = __ENV.CATEGORIES_PATH;
const MAX_ID = parseInt(__ENV.MAX_ID || '10000', 10);
const REQUEST_TIMEOUT = __ENV.REQUEST_TIMEOUT || '10s';

export const options = {
    // med gives us p50; p(95)/p(99) are what actually matter for a realistic profile.
    summaryTrendStats: ['avg', 'min', 'med', 'p(95)', 'p(99)', 'max'],
};

// Weights sum to 100. Mixing page sizes is what makes response length vary: size=1 is a few
// hundred bytes, size=100 is ~20 KB, and /categories is a fixed ~110-row payload.
const MIX = [
    { weight: 55, kind: 'list', size: 20 },
    { weight: 15, kind: 'list', size: 1 },
    { weight: 10, kind: 'list', size: 100 },
    { weight: 15, kind: 'item' },
    { weight: 5, kind: 'categories' },
];

let running = 0;
const TABLE = MIX.map((entry) => ({ ...entry, upto: (running += entry.weight) }));
const TOTAL = running;

export default function () {
    const roll = Math.random() * TOTAL;
    const pick = TABLE.find((entry) => roll < entry.upto);

    let url;
    let endpoint;
    if (pick.kind === 'list') {
        url = BASE + LIST_PATH.replace('{size}', String(pick.size));
        endpoint = 'list:' + pick.size;
    } else if (pick.kind === 'item') {
        const id = 1 + Math.floor(Math.random() * MAX_ID);
        url = BASE + ITEM_PATH.replace('{id}', String(id));
        endpoint = 'item';
    } else {
        url = BASE + CATEGORIES_PATH;
        endpoint = 'categories';
    }

    http.get(url, { timeout: REQUEST_TIMEOUT, tags: { endpoint: endpoint } });
}

// A single machine-readable line for the harness to parse out of stdout.
export function handleSummary(data) {
    const duration = data.metrics.http_req_duration;
    const reqs = data.metrics.http_reqs;
    const failed = data.metrics.http_req_failed;
    const pick = (key) => (duration && duration.values[key] != null ? duration.values[key] : null);

    const summary = {
        reqs: reqs ? reqs.values.count : 0,
        rps: reqs ? reqs.values.rate : 0,
        failed_rate: failed ? failed.values.rate : 0,
        failed_count: failed && failed.values.passes != null ? failed.values.passes : null,
        avg: pick('avg'),
        p50: pick('med'),
        p95: pick('p(95)'),
        p99: pick('p(99)'),
        max: pick('max'),
        dropped: data.metrics.dropped_iterations
            ? data.metrics.dropped_iterations.values.count
            : 0,
    };

    return { stdout: '\nK6SUMMARY ' + JSON.stringify(summary) + '\n' };
}
