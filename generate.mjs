import { writeFileSync } from "node:fs";

const COUNT = parseInt(process.argv[2] || "100", 10);
const STYLE = process.argv[3] || "mixed";
const SPLIT = parseInt(process.argv[4] || "50", 10); // % Indian for mixed

const indianFirst = [
  "Aarav", "Vivaan", "Aditya", "Vihaan", "Arjun", "Sai", "Reyansh", "Ayaan", "Krishna", "Ishaan",
  "Rohan", "Rahul", "Amit", "Vikram", "Raj", "Sanjay", "Manish", "Deepak", "Suresh", "Nitin",
  "Ananya", "Diya", "Myra", "Sara", "Riya", "Priya", "Neha", "Pooja", "Kavya", "Aisha",
  "Sneha", "Anjali", "Nandini", "Isha", "Meera", "Swati", "Divya", "Ritu", "Shreya", "Tanvi"
];
const indianLast = [
  "Sharma", "Verma", "Patel", "Kumar", "Singh", "Reddy", "Gupta", "Joshi", "Nair", "Mehta",
  "Agarwal", "Chopra", "Malhotra", "Saxena", "Deshmukh", "Menon", "Sethi", "Bajaj", "Rao", "Pillai"
];
const westernFirst = [
  "John", "Michael", "David", "James", "Robert", "William", "Christopher", "Daniel", "Matthew", "Andrew",
  "Emily", "Sarah", "Jessica", "Lisa", "Megan", "Rachel", "Laura", "Amy", "Kate", "Anna",
  "Brian", "Kevin", "Jason", "Ryan", "Nicholas", "Amanda", "Stephanie", "Nicole", "Jennifer", "Michelle"
];
const westernLast = [
  "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Wilson", "Moore",
  "Taylor", "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Martinez", "Robinson"
];

const citiesIN = ["Mumbai", "Delhi", "Bangalore", "Hyderabad", "Chennai", "Kolkata", "Pune", "Ahmedabad", "Jaipur", "Lucknow"];
const citiesUS = ["New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "San Diego", "Dallas", "Austin", "Denver", "Seattle"];
const statesIN = ["Maharashtra", "Delhi", "Karnataka", "Telangana", "Tamil Nadu", "West Bengal", "Maharashtra", "Gujarat", "Rajasthan", "Uttar Pradesh"];
const statesUS = ["NY", "CA", "IL", "TX", "AZ", "CA", "TX", "TX", "CO", "WA"];

const users = [];

function pick(arr) { return arr[Math.floor(Math.random() * arr.length)]; }

function makePhone(isIndian) {
  if (isIndian) {
    const cc = pick(["+91", "+91", "+91", "+91", "+91", "+44", "+1"]);
    const digits = cc === "+91" ? 10 : pick([10, 10, 10, 11]);
    return cc + Array.from({ length: digits }, () => Math.floor(Math.random() * 10)).join("");
  }
  return `+1${Math.floor(100 + Math.random() * 900)}${Math.floor(100 + Math.random() * 900)}${Math.floor(1000 + Math.random() * 9000)}`;
}

for (let i = 1; i <= COUNT; i++) {
  const isIndian = STYLE === "indian" || (STYLE === "mixed" && Math.random() * 100 < SPLIT);
  const first = isIndian ? pick(indianFirst) : pick(westernFirst);
  const last = isIndian ? pick(indianLast) : pick(westernLast);
  const city = isIndian ? pick(citiesIN) : pick(citiesUS);
  const state = isIndian ? pick(statesIN) : pick(statesUS);
  const zip = isIndian ? `${Math.floor(100000 + Math.random() * 900000)}` : `${Math.floor(10000 + Math.random() * 90000)}`;
  const phone = makePhone(isIndian);
  const email = `${first.toLowerCase()}.${last.toLowerCase()}${Math.floor(Math.random() * 99 + 1)}@${isIndian ? pick(["gmail.com", "yahoo.co.in", "outlook.com"]) : pick(["gmail.com", "yahoo.com", "outlook.com"])}`;

  users.push({
    id: i, firstName: first, lastName: last, fullName: `${first} ${last}`,
    phone, email,
    address: { street: `${Math.floor(Math.random() * 9999 + 1)} ${pick(["Main St", "Oak Ave", "Park Rd", "Lake Dr", "Hill Rd", "Sector", "Colony", "Nagar"])}`, city, state, zip, country: isIndian ? "India" : "USA" },
    company: isIndian ? pick(["TCS", "Infosys", "Wipro", "HCL", "Tech Mahindra", "Reliance", "Flipkart", "Zomato"]) : pick(["Google", "Microsoft", "Apple", "Amazon", "Meta", "Netflix", "Uber", "Salesforce"]),
    jobTitle: pick(["Engineer", "Manager", "Analyst", "Consultant", "Developer", "Designer", "Architect", "Lead", "Director", "Specialist"])
  });
}

writeFileSync("fake-users.json", JSON.stringify(users, null, 2));

let vcf = "";
const now = new Date();
for (const u of users) {
  const d = new Date(now - Math.random() * 365 * 86400000);
  const bday = `${String(d.getDate()).padStart(2, "0")}${String(d.getMonth() + 1).padStart(2, "0")}${d.getFullYear() - Math.floor(Math.random() * 40 + 20)}`;
  const rev = d.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
  vcf += `BEGIN:VCARD\nVERSION:3.0\nFN:${u.fullName}\nN:${u.lastName};${u.firstName};;;\nTEL;TYPE=CELL:${u.phone}\nEMAIL:${u.email}\nADR;TYPE=HOME:;;${u.address.street};${u.address.city};${u.address.state};${u.address.zip};${u.address.country}\nORG:${u.company}\nTITLE:${u.jobTitle}\nBDAY:${bday}\nREV:${rev}\nEND:VCARD\n\n`;
}
writeFileSync("contacts_fake.vcf", vcf);

console.log(`Generated ${COUNT} fake users (${STYLE}) → fake-users.json + contacts_fake.vcf`);
