# Add Java libraries to GraalVM from R
java.addToClasspath("../../../target/lib/reactive-streams-1.0.3.jar")
java.addToClasspath("../../../target/lib/neo4j-java-driver-4.0.3.jar")

# This brings in the required classes
graphDatabase <- java.type('org.neo4j.driver.GraphDatabase')
authTokens <- java.type('org.neo4j.driver.AuthTokens')
config <- java.type('org.neo4j.driver.Config')
sessionConfig <- java.type('org.neo4j.driver.SessionConfig')

# This is a call to the static factory method named `driver`
driver <- graphDatabase$driver(
    'bolt://localhost:7687',
    authTokens$basic('neo4j', 'Testing123'),
    config$builder()
        $withMaxConnectionPoolSize(1) # Don't need a bigger pool size for a script
        # $withEncryption() # Uncomment this if you want to connect against https://neo4j.com/aura/
        $build()
)

findConnections <- function (driver) {

    query <- '
        MATCH (:Person {name:$name})-[:ACTED_IN]->(m)<-[:ACTED_IN]-(coActor)
        RETURN DISTINCT coActor
    '

    session <- driver$session(sessionConfig$forDatabase("neo4j"))
    # The R list (which behaves like an associative array) is automatically converted to a Java Map
    coActorsRecords <- session$run(query, list(name="Tom Hanks"))$list()

    coActors <- list()
    i <- 1
    for (record in coActorsRecords) {
        coActors[[i]] <- record$get('coActor')$get('name')$asString()
        i <- i + 1
    }

    session$close()
    return(coActors)
}

connections <- findConnections(driver)

for(connection in connections) {
    print(connection)
}


driver$close()