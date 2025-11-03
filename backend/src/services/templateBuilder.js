/**
 * Template builder for deterministic, structured responses
 * Generates plain-text templates before calling Groq to ensure accuracy
 */

/**
 * Build template for latest metric response
 * @param {object} result - Result from metricsService.getLatestMetric
 * @param {string} metricName - Database field name
 * @returns {string} Plain-text template
 */
function buildLatestMetricTemplate(result, metricName) {
  if (!result) return null;

  const friendlyName = metricName
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, str => str.toUpperCase())
    .trim();
  
  const dateStr = new Date(result.date).toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });

  let valueStr = result.value;
  if (typeof result.value === 'number') {
    valueStr = result.value.toFixed(1);
  }

  const template = `Your latest ${friendlyName.toLowerCase()} reading is ${valueStr}, recorded on ${dateStr}.`;
  return template;
}

/**
 * Build template for metric on date response
 * @param {object} result - Result from metricsService.getMetricOnDate
 * @param {string} metricName - Database field name
 * @param {string} requestedDate - Date user asked about
 * @returns {string} Plain-text template
 */
function buildMetricOnDateTemplate(result, metricName, requestedDate) {
  if (!result) {
    const dateStr = new Date(requestedDate).toLocaleDateString('en-US', {
      month: 'long',
      day: 'numeric',
      year: 'numeric',
    });
    return `I could not find data for ${metricName} on ${dateStr}. That date may be outside the available data range.`;
  }

  const friendlyName = metricName
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, str => str.toUpperCase())
    .trim();

  const dateStr = new Date(result.date).toLocaleDateString('en-US', {
    month: 'long',
    day: 'numeric',
    year: 'numeric',
  });

  let valueStr = result.value;
  if (typeof result.value === 'number') {
    valueStr = result.value.toFixed(1);
  }

  const template = `On ${dateStr}, your ${friendlyName.toLowerCase()} was ${valueStr}.`;
  return template;
}

/**
 * Build template for average metric response
 * @param {object} result - Result from metricsService.getMetricAverage
 * @param {string} metricName - Database field name
 * @returns {string} Plain-text template
 */
function buildMetricAverageTemplate(result, metricName) {
  if (!result) return null;

  const friendlyName = metricName
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, str => str.toUpperCase())
    .trim();

  const avgStr = result.average.toFixed(1);
  const template = `Over the past ${result.days} days, your average ${friendlyName.toLowerCase()} was ${avgStr} (based on ${result.count} data points).`;
  return template;
}

/**
 * Build template for trend metric response
 * @param {object} result - Result from metricsService.getMetricTrend
 * @param {string} metricName - Database field name
 * @returns {string} Plain-text template
 */
function buildMetricTrendTemplate(result, metricName) {
  if (!result) return null;

  const friendlyName = metricName
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, str => str.toUpperCase())
    .trim();

  const trendWord = result.trend === 'increasing' ? 'trending upward' :
                     result.trend === 'decreasing' ? 'trending downward' :
                     'remaining stable';

  const latestStr = typeof result.latest === 'number' ? result.latest.toFixed(1) : result.latest;
  const oldestStr = typeof result.oldest === 'number' ? result.oldest.toFixed(1) : result.oldest;

  const template = `Your ${friendlyName.toLowerCase()} is ${trendWord} over the past ${result.days} days. It was ${oldestStr} at the start of the period and is now ${latestStr} (analyzed ${result.count} data points).`;
  return template;
}

/**
 * Build template for symptom report
 * @param {object} intent - Symptom intent object
 * @returns {string} Plain-text template
 */
function buildSymptomTemplate(intent) {
  const urgencyResponses = {
    urgent: 'This could be serious. If your symptoms are severe or worsening, please seek immediate medical attention or call emergency services.',
    moderate: 'I understand you are experiencing discomfort. If symptoms persist or worsen, please consult a healthcare professional.',
    low: 'I hear that you are not feeling well. Here are some general wellness suggestions, but if symptoms continue, consider seeing a doctor.',
  };

  const urgencyText = urgencyResponses[intent.urgency] || urgencyResponses.moderate;
  
  const template = `You mentioned experiencing ${intent.symptom}. ${urgencyText}`;
  return template;
}

/**
 * Build template for lifestyle goal
 * @param {object} intent - Goal intent object
 * @param {object} recentData - Recent metrics related to the goal
 * @returns {string} Plain-text template
 */
function buildGoalTemplate(intent, recentData = null) {
  const goalMessages = {
    weight_loss: 'Weight loss requires a combination of balanced nutrition and regular physical activity.',
    weight_gain: 'Healthy weight gain involves eating nutrient-dense foods and strength training.',
    improve_sleep: 'Improving sleep quality often involves maintaining a consistent schedule and creating a calming bedtime routine.',
    increase_activity: 'Increasing your activity level can start with small steps, like adding short walks throughout the day.',
    lower_stress: 'Managing stress effectively involves relaxation techniques, regular exercise, and adequate sleep.',
  };

  const message = goalMessages[intent.goal] || 'I can help you work toward your wellness goals.';
  
  let template = `You want to work on ${intent.goal.replace(/_/g, ' ')}. ${message}`;
  
  if (recentData && Object.keys(recentData).length > 0) {
    template += ' Based on your recent data, I can provide personalized recommendations.';
  }
  
  return template;
}

module.exports = {
  buildLatestMetricTemplate,
  buildMetricOnDateTemplate,
  buildMetricAverageTemplate,
  buildMetricTrendTemplate,
  buildSymptomTemplate,
  buildGoalTemplate,
};

