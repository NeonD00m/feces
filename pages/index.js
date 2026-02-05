import Link from "@docusaurus/Link";
import useDocusaurusContext from "@docusaurus/useDocusaurusContext";
import Layout from "@theme/Layout";
import clsx from "clsx";
import React from "react";
import "./home.css";
import styles from "./index.module.css";

const FEATURES = [
  {
    image:
      "https://raw.githubusercontent.com/NeonD00m/feces/refs/heads/main/images/basics.png",
    title: "Integrated with Jecs",
    description: (
      <>
        One line to replicate either a specific component or a whole entity!
        <br />
        <br />
        In the example you can see that we show how both methods would work,
        though in reality the pairs method is redundant if you are also adding
        the replicated component straight to the entity.
        <br />
        <br />
        Targeting certain components to replicate is very useful so that on the
        server, you do not have to split up entities into one public version,
        and one non-replicating version.
      </>
    ),
  },
  {
    image:
      "https://raw.githubusercontent.com/NeonD00m/feces/refs/heads/main/images/players.png",
    title: "Player-specific replication",
    description: (
      <>
        Allows you to define which players to replicate to in a variety of ways.
        <br />
        (Also all of these work with pair-targeting of components!)
        <br />
        <br />
        <b>Player:</b> You probably don't need an explanation for this one.
        <br />
        <br />
        <b>Tables:</b> Read as an inclusive list of players to replicate to.
        <br />
        <br />
        <b>Functions:</b> Called for each player, expecting a boolean to
        determine if they should be replicated to.
      </>
    ),
  },
  {
    image:
      "https://raw.githubusercontent.com/NeonD00m/feces/refs/heads/main/images/visual-explanation.png",
    title: "Intuitive Concepts",
    description: (
      <>
        So intuitive that even a gorilla can get the idea!
        <br />
        <br />
        Be surprised by how fast you can get your project up and running with
        feces handling your replication needs.
        <br />
        <br />
        In the initial stages of development when we started actually making a
        game with feces, we were kind of shocked by how fast we got features
        working, and thought we were missing something. We weren't, that's just
        just the developer experience with feces!
      </>
    ),
  },
];

function Feature({ image, title, description, Art }) {
  return (
    <div className={styles.feature}>
      {image && <img className={styles.featureSvg} alt={title} src={image} />}
      <div className={styles.featureDescription}>
        <h3>{title}</h3>
        <p>{description}</p>
      </div>
    </div>
  );
}

export function HomepageFeatures() {
  if (!FEATURES) return null;

  return (
    <section>
      <div className="container">
        <div className={styles.features}>
          {FEATURES.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className={clsx("hero", styles.heroBanner)}>
      <div className="container">
        <h1 className="hero__title">
          <img
            src="https://raw.githubusercontent.com/NeonD00m/feces/refs/heads/main/images/thelogo.png"
            className="bigLogo"
            alt="feces"
          />
        </h1>
        <p
          className="hero__subtitle"
          style={{
            color: "#a2a2a5",
            fontSize: "1.5rem",
            fontWeight: "300",
            marginTop: "-1rem",
          }}
        >
          (a.k.a "Fast Entity Component Export System")
        </p>
        <p
          className="hero__subtitle"
          style={{ color: "#a2a2a5", fontWeight: "600" }}
        >
          {siteConfig.tagline}
        </p>
        <div className={styles.buttons} style={{ marginTop: "1.5rem" }}>
          <Link
            className="button button--secondary button--lg"
            to="/docs/intro"
            style={{
              borderRadius: "9999px",
              color: "white",
              backgroundColor: "blue",
              borderColor: "blue",
            }}
          >
            Get Started
          </Link>
          <Link
            className="button button--secondary button--lg"
            to="/api/feces"
            style={{
              borderRadius: "9999px",
              color: "white",
              backgroundColor: "#323234",
              borderColor: "#323234",
            }}
          >
            API Reference
          </Link>
        </div>
      </div>
    </header>
  );
}

export default function Home() {
  const { siteConfig, tagline } = useDocusaurusContext();
  return (
    <Layout title={siteConfig.title} description={tagline}>
      <HomepageHeader />
      <main>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
