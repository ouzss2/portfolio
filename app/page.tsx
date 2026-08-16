import { getProfile, getSkillsByCategory } from "@/lib/queries";

export default async function Home() {
  const profile = await getProfile();
  const groups = await getSkillsByCategory();

  return (
    <main className="mx-auto max-w-2xl p-8 font-mono text-sm">
      <h1 className="text-2xl font-bold">{profile?.fullName}</h1>
      <p className="text-neutral-500">{profile?.headline.en}</p>
      <p className="mt-4">{profile?.bio.en}</p>

      {groups.map(({ category, skills }) => (
        <section key={category.id} className="mt-6">
          <h2 className="font-semibold">{category.name.en}</h2>
          <ul className="text-neutral-600">
            {skills.map((s) => (
              <li key={s.id}>
                {s.name} — level {s.level} · {s.yearsExperience}y
              </li>
            ))}
          </ul>
        </section>
      ))}
    </main>
  );
}