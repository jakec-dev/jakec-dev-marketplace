# Component API

Shape a component's API as compound parts the consumer composes, the way shadcn/ui does. Export a part for
anything the consumer renders, places or fills, such as a title, a value or a footer:
`<Card><CardTitle>Revenue</CardTitle></Card>`, not `<Card title="Revenue" />`. Use a prop only for a choice from a
closed set the component interprets, such as `variant` or `size`, and for state.
