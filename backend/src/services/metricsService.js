const HealthMetric = require('../models/HealthMetric');

/**
 * Service for querying health metrics with specific intents
 * Provides precise data retrieval for chat analytics
 */

/**
 * Get the most recent value for a specific metric
 * @param {string} metricName - Database field name (e.g., 'stepCount')
 * @param {string} userUid - User UID to query
 * @returns {Promise<{value: any, date: Date}|null>}
 */
async function getLatestMetric(metricName, userUid) {
  try {
    const doc = await HealthMetric.findOne({ userUid })
      .sort({ date: -1 })
      .select({ [metricName]: 1, date: 1 })
      .lean();

    if (!doc || doc[metricName] === undefined || doc[metricName] === null) {
      return null;
    }

    return {
      value: doc[metricName],
      date: doc.date,
    };
  } catch (err) {
    console.error(`[metricsService] getLatestMetric error for ${metricName}:`, err.message);
    return null;
  }
}

/**
 * Get metric value for a specific date
 * @param {string} metricName - Database field name
 * @param {string} dateStr - Date in YYYY-MM-DD format
 * @param {string} userUid - User UID to query
 * @returns {Promise<{value: any, date: Date}|null>}
 */
async function getMetricOnDate(metricName, dateStr, userUid) {
  try {
    const targetDate = new Date(dateStr);
    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);

    const doc = await HealthMetric.findOne({
      userUid,
      date: { $gte: targetDate, $lt: nextDay },
    })
      .select({ [metricName]: 1, date: 1 })
      .lean();

    if (!doc || doc[metricName] === undefined || doc[metricName] === null) {
      return null;
    }

    return {
      value: doc[metricName],
      date: doc.date,
    };
  } catch (err) {
    console.error(`[metricsService] getMetricOnDate error for ${metricName} on ${dateStr}:`, err.message);
    return null;
  }
}

/**
 * Get average value of a metric over the past N days
 * @param {string} metricName - Database field name
 * @param {number} days - Number of days to average
 * @param {string} userUid - User UID to query
 * @returns {Promise<{average: number, count: number, days: number}|null>}
 */
async function getMetricAverage(metricName, days, userUid) {
  try {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);

    const docs = await HealthMetric.find({
      userUid,
      date: { $gte: cutoff },
    })
      .select({ [metricName]: 1 })
      .lean();

    const values = docs
      .map((d) => d[metricName])
      .filter((v) => v !== undefined && v !== null && Number.isFinite(Number(v)));

    if (!values.length) return null;

    const sum = values.reduce((acc, val) => acc + Number(val), 0);
    const average = sum / values.length;

    return {
      average,
      count: values.length,
      days,
    };
  } catch (err) {
    console.error(`[metricsService] getMetricAverage error for ${metricName}:`, err.message);
    return null;
  }
}

/**
 * Get trend for a metric over the past N days (increasing/decreasing/stable)
 * @param {string} metricName - Database field name
 * @param {number} days - Number of days to analyze
 * @param {string} userUid - User UID to query
 * @returns {Promise<{trend: string, slope: number, latest: number, oldest: number, count: number}|null>}
 */
async function getMetricTrend(metricName, days, userUid) {
  try {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - days);

    const docs = await HealthMetric.find({
      userUid,
      date: { $gte: cutoff },
    })
      .sort({ date: -1 })
      .select({ [metricName]: 1, date: 1 })
      .lean();

    const values = docs
      .map((d) => Number(d[metricName]))
      .filter((v) => Number.isFinite(v));

    if (values.length < 2) return null;

    const latest = values[0];
    const oldest = values[values.length - 1];
    const delta = latest - oldest;
    const slope = delta / values.length;

    // Determine trend based on delta magnitude relative to typical metric scale
    let trend = 'stable';
    const absSlope = Math.abs(slope);

    // Adaptive thresholds based on metric type (simple heuristic)
    let threshold = 0.1;
    if (['stepCount', 'caloriesBurned'].includes(metricName)) {
      threshold = 100;
    } else if (['weightKg', 'bmi'].includes(metricName)) {
      threshold = 0.3;
    } else if (['sleepDurationHr', 'remSleepHr'].includes(metricName)) {
      threshold = 0.2;
    } else if (['restingHeartRateBpm', 'stressLevel'].includes(metricName)) {
      threshold = 2;
    }

    if (absSlope > threshold) {
      trend = delta > 0 ? 'increasing' : 'decreasing';
    }

    return {
      trend,
      slope,
      latest,
      oldest,
      count: values.length,
      days,
    };
  } catch (err) {
    console.error(`[metricsService] getMetricTrend error for ${metricName}:`, err.message);
    return null;
  }
}

/**
 * Get metric value for a date, falling back to nearest available date within a window
 * @param {string} metricName - Database field name
 * @param {string} dateStr - Target date in YYYY-MM-DD format
 * @param {string} userUid - User UID to query
 * @param {number} windowDays - Number of days to search before/after (default 3)
 * @returns {Promise<{value: any, date: Date, offset: number}|null>}
 */
async function getMetricNearestToDate(metricName, dateStr, userUid, windowDays = 3) {
  try {
    // First try exact date
    const exact = await getMetricOnDate(metricName, dateStr, userUid);
    if (exact) {
      return { ...exact, offset: 0 };
    }

    // Search within window
    const targetDate = new Date(dateStr);
    const startDate = new Date(targetDate);
    startDate.setDate(startDate.getDate() - windowDays);
    const endDate = new Date(targetDate);
    endDate.setDate(endDate.getDate() + windowDays + 1);

    const docs = await HealthMetric.find({
      userUid,
      date: { $gte: startDate, $lt: endDate },
    })
      .select({ [metricName]: 1, date: 1 })
      .sort({ date: -1 })
      .lean();

    const validDocs = docs.filter(d => d[metricName] !== undefined && d[metricName] !== null);
    if (!validDocs.length) return null;

    // Find closest by time difference
    let closest = validDocs[0];
    let minDiff = Math.abs(closest.date.getTime() - targetDate.getTime());

    for (const doc of validDocs) {
      const diff = Math.abs(doc.date.getTime() - targetDate.getTime());
      if (diff < minDiff) {
        minDiff = diff;
        closest = doc;
      }
    }

    const offsetDays = Math.round((closest.date.getTime() - targetDate.getTime()) / (1000 * 60 * 60 * 24));

    return {
      value: closest[metricName],
      date: closest.date,
      offset: offsetDays,
    };
  } catch (err) {
    console.error(`[metricsService] getMetricNearestToDate error for ${metricName}:`, err.message);
    return null;
  }
}

/**
 * Get metric values within a date range
 * @param {string} metricName - Database field name
 * @param {string} startDateStr - Start date in YYYY-MM-DD format
 * @param {string} endDateStr - End date in YYYY-MM-DD format
 * @param {string} userUid - User UID to query
 * @returns {Promise<Array<{value: any, date: Date}>|null>}
 */
async function getMetricInRange(metricName, startDateStr, endDateStr, userUid) {
  try {
    const startDate = new Date(startDateStr);
    const endDate = new Date(endDateStr);
    endDate.setDate(endDate.getDate() + 1); // Include end date

    const docs = await HealthMetric.find({
      userUid,
      date: { $gte: startDate, $lt: endDate },
    })
      .select({ [metricName]: 1, date: 1 })
      .sort({ date: -1 })
      .lean();

    const results = docs
      .filter(d => d[metricName] !== undefined && d[metricName] !== null)
      .map(d => ({
        value: d[metricName],
        date: d.date,
      }));

    return results.length > 0 ? results : null;
  } catch (err) {
    console.error(`[metricsService] getMetricInRange error for ${metricName}:`, err.message);
    return null;
  }
}

/**
 * Get aggregated metric value over a date range
 * @param {string} metricName - Database field name
 * @param {string} startDateStr - Start date in YYYY-MM-DD format
 * @param {string} endDateStr - End date in YYYY-MM-DD format
 * @param {string} userUid - User UID to query
 * @param {string} aggregation - 'avg', 'min', 'max', or 'last'
 * @returns {Promise<{value: number, count: number}|null>}
 */
async function getDailyAggregate(metricName, startDateStr, endDateStr, userUid, aggregation = 'avg') {
  try {
    const values = await getMetricInRange(metricName, startDateStr, endDateStr, userUid);
    if (!values || values.length === 0) return null;

    const numericValues = values
      .map(v => Number(v.value))
      .filter(v => Number.isFinite(v));

    if (numericValues.length === 0) return null;

    let result;
    switch (aggregation) {
      case 'min':
        result = Math.min(...numericValues);
        break;
      case 'max':
        result = Math.max(...numericValues);
        break;
      case 'last':
        result = numericValues[0]; // Already sorted desc
        break;
      case 'avg':
      default:
        result = numericValues.reduce((sum, v) => sum + v, 0) / numericValues.length;
        break;
    }

    return {
      value: result,
      count: numericValues.length,
    };
  } catch (err) {
    console.error(`[metricsService] getDailyAggregate error for ${metricName}:`, err.message);
    return null;
  }
}

module.exports = {
  getLatestMetric,
  getMetricOnDate,
  getMetricAverage,
  getMetricTrend,
  getMetricNearestToDate,
  getMetricInRange,
  getDailyAggregate,
};

