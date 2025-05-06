#!/bin/bash
BLACK_TEXT=$'\033[0;90m'
RED_TEXT=$'\033[0;91m'
GREEN_TEXT=$'\033[0;92m'
YELLOW_TEXT=$'\033[0;93m'
BLUE_TEXT=$'\033[0;94m'
MAGENTA_TEXT=$'\033[0;95m'
CYAN_TEXT=$'\033[0;96m'
WHITE_TEXT=$'\033[0;97m'
RESET_FORMAT=$'\033[0m'
BOLD_TEXT=$'\033[1m'
UNDERLINE_TEXT=$'\033[4m'

clear

echo
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}🚀         INITIATING EXECUTION         🚀${RESET_FORMAT}"
echo "${CYAN_TEXT}${BOLD_TEXT}=========================================${RESET_FORMAT}"
echo

echo "${YELLOW_TEXT}${BOLD_TEXT}✨ Instruction: The first query is about to run! ✨${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"
SELECT
 Events.playerId,
 (Players.firstName || ' ' || Players.lastName) AS playerName,
 SUM(IF(Tags2Name.Label = 'assist', 1, 0)) AS numAssists
FROM
 \`soccer.events\` Events,
 Events.tags Tags
LEFT JOIN
 \`soccer.tags2name\` Tags2Name ON
  Tags.id = Tags2Name.Tag
LEFT JOIN
 \`soccer.players\` Players ON
  Events.playerId = Players.wyId
GROUP BY
 playerId, playerName
ORDER BY
 numAssists
"

echo
echo "${GREEN_TEXT}${BOLD_TEXT}🎯 Next Up: Team Passing Analysis! 🎯${RESET_FORMAT}"
echo "${GREEN_TEXT}This query calculates the number of passes, average pass distance, and average accurate pass distance for each team. Let's see who has the best passing game! 👟${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"
WITH
Passes AS
(
 SELECT
  *,
  (1801 IN UNNEST(tags.id)) AS accuratePass,
  (CASE
    WHEN ARRAY_LENGTH(positions) != 2 THEN NULL
    ELSE
     SQRT(
      POW(
        (positions[ORDINAL(2)].x - positions[ORDINAL(1)].x) * 105/100,
        2) +
      POW(
        (positions[ORDINAL(2)].y - positions[ORDINAL(1)].y) * 68/100,
        2)
      )
    END) AS passDistance
 FROM
  \`soccer.events\`
 WHERE
  eventName = 'Pass'
)
SELECT
 Passes.teamId,
 Teams.name AS team,
 Teams.area.name AS teamArea,
 COUNT(Passes.Id) AS numPasses,
 AVG(Passes.passDistance) AS avgPassDistance,
 SAFE_DIVIDE(
  SUM(IF(Passes.accuratePass, Passes.passDistance, 0)),
  SUM(IF(Passes.accuratePass, 1, 0))
  ) AS avgAccuratePassDistance
FROM
 Passes
LEFT JOIN
 \`soccer.teams\` Teams ON
  Passes.teamId = Teams.wyId
WHERE
 Teams.type = 'club'
GROUP BY
 teamId, team, teamArea
ORDER BY
 avgPassDistance

"

echo
echo "${BLUE_TEXT}${BOLD_TEXT}🥅 Shot Distance Insights Coming Through! 🥅${RESET_FORMAT}"
echo "${BLUE_TEXT}This query analyzes shots based on their distance from the goal. We'll see the number of shots, goals, and goal percentage for different distances. How far is too far? 🤔${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"
WITH
Shots AS
(
 SELECT
  *,
  (101 IN UNNEST(tags.id)) AS isGoal,
  SQRT(
   POW(
    (100 - positions[ORDINAL(1)].x) * 105/100,
    2) +
   POW(
    (50 - positions[ORDINAL(1)].y) * 68/100,
    2)
    ) AS shotDistance
 FROM
  \`soccer.events\`
 WHERE
  eventName = 'Shot' OR
  (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty'))
)
SELECT
 ROUND(shotDistance, 0) AS ShotDistRound0,
 COUNT(*) AS numShots,
 SUM(IF(isGoal, 1, 0)) AS numGoals,
 AVG(IF(isGoal, 1, 0)) AS goalPct
FROM
 Shots
WHERE
 shotDistance <= 50
GROUP BY
 ShotDistRound0
ORDER BY
 ShotDistRound0
"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}📐 Analyzing Shot Angles Now! 📐${RESET_FORMAT}"
echo "${MAGENTA_TEXT}The final query explores the relationship between the angle of a shot and its success rate. Discover the optimal angles for scoring! 🏆${RESET_FORMAT}"

bq query --use_legacy_sql=false \
"
WITH
Shots AS
(
 SELECT
  *,
  (101 IN UNNEST(tags.id)) AS isGoal,
  LEAST(positions[ORDINAL(1)].x, 99.99999) * 105/100 AS shotXAbs,
  LEAST(positions[ORDINAL(1)].y, 99.99999) * 68/100 AS shotYAbs
 FROM
  \`soccer.events\`
 WHERE
  eventName = 'Shot' OR
  (eventName = 'Free Kick' AND subEventName IN ('Free kick shot', 'Penalty'))
),
ShotsWithAngle AS
(
 SELECT
  Shots.*,
  SAFE.ACOS(
    SAFE_DIVIDE(
     (
      (POW(105 - shotXAbs, 2) + POW(34 + (7.32/2) - shotYAbs, 2)) +
      (POW(105 - shotXAbs, 2) + POW(34 - (7.32/2) - shotYAbs, 2)) -
      POW(7.32, 2)
     ),
     (2 *
      SQRT(POW(105 - shotXAbs, 2) + POW(34 + 7.32/2 - shotYAbs, 2)) *
      SQRT(POW(105 - shotXAbs, 2) + POW(34 - 7.32/2 - shotYAbs, 2))
     )
    )
  ) * 180 / ACOS(-1)
  AS shotAngle
 FROM
  Shots
)
SELECT
 ROUND(shotAngle, 0) AS ShotAngleRound0,
 COUNT(*) AS numShots,
 SUM(IF(isGoal, 1, 0)) AS numGoals,
 AVG(IF(isGoal, 1, 0)) AS goalPct
FROM
 ShotsWithAngle
GROUP BY
 ShotAngleRound0
ORDER BY
 ShotAngleRound0
"

echo
echo "${MAGENTA_TEXT}${BOLD_TEXT}💖 Enjoyed this script and the video? Consider subscribing to Arcade Crew! 👇${RESET_FORMAT}"
echo "${BLUE_TEXT}${BOLD_TEXT}${UNDERLINE_TEXT}https://www.youtube.com/@Arcade61432${RESET_FORMAT}"
echo
